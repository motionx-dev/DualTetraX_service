# DualTetraX Services - AWS 배포 가이드

**버전**: 1.0
**날짜**: 2026-02-08
**인프라**: AWS CDK (TypeScript)
**환경**: Dev, Prod

---

## 1. 개요

본 가이드는 Infrastructure as Code (AWS CDK)를 사용하여 DualTetraX Services를 AWS에 완전히 배포하는 방법을 다룹니다.

### 1.1 스타트업을 위한 데이터베이스 옵션

**중요**: 펀딩 단계와 사용자 수에 따라 적절한 데이터베이스 티어를 선택하세요.

| 옵션 | 적합한 단계 | 월 비용 | 최대 사용자 수 | 자동 확장 | 고가용성 |
|------|------------|---------|---------------|----------|---------|
| **RDS db.t4g.micro** | **MVP/스타트업** | **$15-30** | **~5,000명** | ❌ 수동 | ❌ Single-AZ |
| RDS db.t4g.small | 성장 단계 | $30-50 | ~10,000명 | ❌ 수동 | ✅ Multi-AZ (선택) |
| Aurora Serverless v2 | 시리즈 A 이상 | $50-200 | 100,000명 이상 | ✅ 자동 | ✅ Multi-AZ |

**스타트업 권장 경로:**
1. **시작**: RDS db.t4g.micro ($15/월) - 제품-시장 적합성 검증
2. **성장**: RDS db.t4g.small ($30/월) - 활성 사용자 1,000명 이상일 때
3. **확장**: Aurora Serverless v2 ($100+/월) - 시리즈 A 펀딩 이후

### 1.2 사용되는 AWS 서비스 (비용 최적화)

| 서비스 | 용도 | Dev 비용 예상 | Prod 비용 예상 |
|--------|------|--------------|---------------|
| **RDS PostgreSQL (t4g.micro)** | 데이터베이스 | ~$15/월 | ~$30/월 |
| **Lambda** | API 백엔드 | ~$5/월 | ~$20/월 |
| **API Gateway** | REST API 엔드포인트 | ~$3/월 | ~$10/월 |
| **Cognito** | 사용자 인증 | 무료 (< 50K MAU) | 무료 (< 50K MAU) |
| **S3** | 파일 저장소 (펌웨어, 이미지) | ~$1/월 | ~$5/월 |
| **CloudFront** | 프론트엔드용 CDN | ~$1/월 | ~$10/월 |
| **Route 53** | DNS | ~$1/월 | ~$1/월 |
| **Secrets Manager** | API 키, DB 비밀번호 | ~$1/월 | ~$1/월 |
| **CloudWatch** | 로깅 및 모니터링 | ~$5/월 | ~$15/월 |
| **합계** | | **~$32/월** | **~$92/월** |

**참고**: 비용은 초기 단계 (< 1,000 활성 사용자) 기준 예상치입니다. 실제 비용은 달라질 수 있습니다.

**프리시드 스타트업을 위한 대안 (<$20/월 예산):**
- Supabase 무료 티어 사용 ($0/월, 500MB 제한, 무제한 API 요청)
- 백엔드 코드가 이미 Supabase SDK 사용 중 - 코드 변경 불필요
- 무료 티어를 초과하거나 펀딩 확보 시 AWS로 마이그레이션

---

## 2. 사전 요구사항

### 2.1 필수 도구

```bash
# Node.js 18+ 설치
brew install node

# AWS CDK 설치
npm install -g aws-cdk

# AWS CLI 설치
brew install awscli

# AWS 자격 증명 설정
aws configure
```

### 2.2 AWS 계정 설정

1. **AWS 계정 생성** (없는 경우)
   - 방문: https://aws.amazon.com
   - 등록 완료

2. **CDK용 IAM 사용자 생성**
   ```bash
   # AWS 콘솔에서 사용자 생성
   # IAM > Users > Add user
   # 이름: dualtetrax-cdk-deployer
   # 권한: AdministratorAccess (초기 설정용)

   # Access Key ID와 Secret Access Key 저장
   aws configure --profile dualtetrax
   ```

3. **CDK 부트스트랩** (1회성 설정)
   ```bash
   cdk bootstrap aws://ACCOUNT-ID/us-east-1 --profile dualtetrax
   ```

---

## 3. 프로젝트 구조

```
services/
├── infrastructure/                    # AWS CDK 코드
│   ├── bin/
│   │   └── dualtetrax-stack.ts       # CDK 앱 진입점
│   ├── lib/
│   │   ├── database-stack.ts         # RDS Aurora
│   │   ├── api-stack.ts              # Lambda + API Gateway
│   │   ├── auth-stack.ts             # Cognito
│   │   ├── storage-stack.ts          # S3 + CloudFront
│   │   └── monitoring-stack.ts       # CloudWatch + Alarms
│   ├── cdk.json
│   ├── package.json
│   └── tsconfig.json
│
├── backend/                           # Lambda 함수 (기존)
├── frontend/                          # React 앱 (기존)
└── doc/                               # 문서 (기존)
```

---

## 4. CDK 스택 구현

### 4.1 CDK 프로젝트 초기화

```bash
cd services
mkdir infrastructure
cd infrastructure

cdk init app --language typescript
npm install @aws-cdk/aws-rds @aws-cdk/aws-lambda @aws-cdk/aws-apigateway @aws-cdk/aws-cognito @aws-cdk/aws-s3 @aws-cdk/aws-cloudfront
```

### 4.2 데이터베이스 스택 옵션

#### 옵션 A: 비용 최적화 RDS PostgreSQL (스타트업 권장)

**파일**: `services/infrastructure/lib/database-stack.ts`

```typescript
import * as cdk from 'aws-cdk-lib';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { Construct } from 'constructs';

export interface DatabaseStackProps extends cdk.StackProps {
  environment: 'dev' | 'prod';
}

export class DatabaseStack extends cdk.Stack {
  public readonly instance: rds.DatabaseInstance;
  public readonly secret: secretsmanager.Secret;

  constructor(scope: Construct, id: string, props: DatabaseStackProps) {
    super(scope, id, props);

    const vpc = new ec2.Vpc(this, 'DualTetraXVPC', {
      maxAzs: 1,
      natGateways: 0,
      subnetConfiguration: [
        {
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          name: 'Isolated',
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
        },
      ],
    });

    this.secret = new secretsmanager.Secret(this, 'DBSecret', {
      secretName: `qp-dualtetrax-${props.environment}-db-credentials`,
      generateSecretString: {
        secretStringTemplate: JSON.stringify({ username: 'dbadmin' }),
        generateStringKey: 'password',
        excludePunctuation: true,
      },
    });

    this.instance = new rds.DatabaseInstance(this, 'DualTetraXDB', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_15_3,
      }),
      credentials: rds.Credentials.fromSecret(this.secret),
      databaseName: `qp_dualtetrax_${props.environment}`,
      instanceType: ec2.InstanceType.of(
        ec2.InstanceClass.T4G,
        props.environment === 'prod' ? ec2.InstanceSize.SMALL : ec2.InstanceSize.MICRO
      ),
      vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_ISOLATED },
      allocatedStorage: 20,
      storageType: rds.StorageType.GP3,
      publiclyAccessible: false,
      multiAz: false,
      backupRetention: cdk.Duration.days(props.environment === 'prod' ? 30 : 7),
      preferredBackupWindow: '03:00-04:00',
      deleteAutomatedBackups: props.environment !== 'prod',
      removalPolicy: props.environment === 'prod'
        ? cdk.RemovalPolicy.SNAPSHOT
        : cdk.RemovalPolicy.DESTROY,
    });

    new cdk.CfnOutput(this, 'DBInstanceEndpoint', {
      value: this.instance.dbInstanceEndpointAddress,
      description: '데이터베이스 인스턴스 엔드포인트',
    });

    new cdk.CfnOutput(this, 'DBSecretArn', {
      value: this.secret.secretArn,
      description: '데이터베이스 자격 증명 시크릿 ARN',
    });
  }
}
```

**비용**: ~$15/월 (dev), ~$30/월 (prod)

**장점:**
- ✅ Aurora보다 **2배 저렴** ($15 vs $50/월)
- ✅ 관리형 백업 및 패치
- ✅ 나중에 Aurora로 쉽게 업그레이드 가능
- ✅ 5,000명 미만 사용자에게 완벽

**단점:**
- ❌ 자동 확장 불가 (수동 인스턴스 크기 조정 필요)
- ❌ Single-AZ (dev) - 자동 장애 조치 없음
- ❌ 읽기 전용 복제본 수동 설정 필요

---

#### 옵션 B: Aurora Serverless v2 (펀딩 받은 스타트업 / 프로덕션 규모)

**파일**: `services/infrastructure/lib/database-stack-aurora.ts`

```typescript
import * as cdk from 'aws-cdk-lib';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { Construct } from 'constructs';

export interface DatabaseStackProps extends cdk.StackProps {
  environment: 'dev' | 'prod';
}

export class DatabaseStackAurora extends cdk.Stack {
  public readonly cluster: rds.DatabaseCluster;
  public readonly secret: secretsmanager.Secret;

  constructor(scope: Construct, id: string, props: DatabaseStackProps) {
    super(scope, id, props);

    const vpc = new ec2.Vpc(this, 'DualTetraXVPC', {
      maxAzs: 2,
      natGateways: 1,
    });

    this.secret = new secretsmanager.Secret(this, 'DBSecret', {
      secretName: `qp-dualtetrax-${props.environment}-db-credentials`,
      generateSecretString: {
        secretStringTemplate: JSON.stringify({ username: 'dbadmin' }),
        generateStringKey: 'password',
        excludePunctuation: true,
      },
    });

    this.cluster = new rds.DatabaseCluster(this, 'DualTetraXDB', {
      engine: rds.DatabaseClusterEngine.auroraPostgres({
        version: rds.AuroraPostgresEngineVersion.VER_15_3,
      }),
      credentials: rds.Credentials.fromSecret(this.secret),
      defaultDatabaseName: `qp_dualtetrax_${props.environment}`,
      writer: rds.ClusterInstance.serverlessV2('Writer'),
      readers: [
        rds.ClusterInstance.serverlessV2('Reader', { scaleWithWriter: true }),
      ],
      vpc,
      serverlessV2MinCapacity: 0.5,
      serverlessV2MaxCapacity: 2,
      backup: {
        retention: cdk.Duration.days(props.environment === 'prod' ? 30 : 7),
      },
    });

    new cdk.CfnOutput(this, 'DBClusterEndpoint', {
      value: this.cluster.clusterEndpoint.socketAddress,
    });
  }
}
```

**비용**: ~$50/월 (dev), ~$100/월 (prod)

**장점:**
- ✅ 자동 확장 (0.5 → 2 ACU)
- ✅ Multi-AZ 고가용성
- ✅ 자동 읽기 전용 복제본
- ✅ 100,000명 이상 사용자 지원

**단점:**
- ❌ RDS 단일 인스턴스보다 **3배 비쌈**
- ❌ 5,000명 미만 사용자에게는 과한 스펙

---

**마이그레이션 경로**: 옵션 A (RDS)로 시작하여, 사용자 수가 10,000명 이상이거나 시리즈 A 펀딩 확보 시 옵션 B (Aurora)로 마이그레이션

### 4.3 API 스택 (Lambda + API Gateway)

**파일**: `services/infrastructure/lib/api-stack.ts`

```typescript
import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export interface ApiStackProps extends cdk.StackProps {
  environment: 'dev' | 'prod';
  databaseSecretArn: string;
}

export class ApiStack extends cdk.Stack {
  public readonly api: apigateway.RestApi;

  constructor(scope: Construct, id: string, props: ApiStackProps) {
    super(scope, id, props);

    const apiFunction = new lambda.Function(this, 'ApiFunction', {
      functionName: `qp-dualtetrax-${props.environment}-api`,
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset('../backend'),
      handler: 'index.handler',
      environment: {
        NODE_ENV: props.environment === 'prod' ? 'production' : 'development',
        DB_SECRET_ARN: props.databaseSecretArn,
      },
      timeout: cdk.Duration.seconds(30),
      memorySize: 512,
    });

    apiFunction.addToRolePolicy(new iam.PolicyStatement({
      actions: ['secretsmanager:GetSecretValue'],
      resources: [props.databaseSecretArn],
    }));

    this.api = new apigateway.RestApi(this, 'DualTetraXAPI', {
      restApiName: `qp-dualtetrax-${props.environment}-api`,
      description: `DualTetraX API - ${props.environment}`,
      deployOptions: {
        stageName: props.environment,
        throttlingRateLimit: 100,
        throttlingBurstLimit: 200,
        loggingLevel: apigateway.MethodLoggingLevel.INFO,
      },
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    const integration = new apigateway.LambdaIntegration(apiFunction);

    const api = this.api.root.addResource('api');

    api.addResource('health').addMethod('GET', integration);

    const auth = api.addResource('auth');
    auth.addResource('signup').addMethod('POST', integration);
    auth.addResource('login').addMethod('POST', integration);
    auth.addResource('logout').addMethod('POST', integration);

    const devices = api.addResource('devices');
    devices.addMethod('GET', integration);
    devices.addMethod('POST', integration);

    const sessions = api.addResource('sessions');
    sessions.addMethod('GET', integration);
    sessions.addMethod('POST', integration);

    new cdk.CfnOutput(this, 'ApiUrl', {
      value: this.api.url,
      description: 'API Gateway URL',
    });
  }
}
```

### 4.4 메인 CDK 앱

**파일**: `services/infrastructure/bin/dualtetrax-stack.ts`

```typescript
#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { DatabaseStack } from '../lib/database-stack';
import { ApiStack } from '../lib/api-stack';

const app = new cdk.App();

const environment = app.node.tryGetContext('environment') || 'dev';

const dbStack = new DatabaseStack(app, `DualTetraXDB-${environment}`, {
  environment: environment as 'dev' | 'prod',
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: 'us-east-1',
  },
});

const apiStack = new ApiStack(app, `DualTetraXAPI-${environment}`, {
  environment: environment as 'dev' | 'prod',
  databaseSecretArn: dbStack.secret.secretArn,
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: 'us-east-1',
  },
});

apiStack.addDependency(dbStack);

app.synth();
```

---

## 5. 배포 단계

### 5.1 개발 환경 배포

```bash
cd services/infrastructure

npm install

cdk deploy DualTetraXDB-dev --profile dualtetrax

cdk deploy DualTetraXAPI-dev --profile dualtetrax

cdk outputs DualTetraXAPI-dev
```

### 5.2 프로덕션 환경 배포

```bash
cdk deploy DualTetraXDB-prod -c environment=prod --profile dualtetrax
cdk deploy DualTetraXAPI-prod -c environment=prod --profile dualtetrax
```

### 5.3 데이터베이스 스키마 초기화

```bash
DB_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name DualTetraXDB-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`DBInstanceEndpoint`].OutputValue' \
  --output text \
  --profile dualtetrax)

DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id qp-dualtetrax-dev-db-credentials \
  --query 'SecretString' \
  --output text \
  --profile dualtetrax | jq -r '.password')

psql -h $DB_ENDPOINT -U dbadmin -d qp_dualtetrax_dev

\i ../doc/database_schema.sql
```

---

## 6. GitHub Actions를 통한 CI/CD

**파일**: `services/.github/workflows/deploy-aws-dev.yml`

```yaml
name: Deploy to AWS Dev

on:
  push:
    branches: [dev]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Install dependencies
        run: |
          cd services/infrastructure
          npm install

      - name: Deploy CDK stack
        run: |
          cd services/infrastructure
          cdk deploy DualTetraXAPI-dev --require-approval never
```

---

## 7. 비용 최적화 전략

### 7.1 스타트업 예산 분석 (<$50/월)

**비용 최적화 스택:**

| 서비스 | 구성 | 월 비용 |
|--------|------|---------|
| RDS PostgreSQL | db.t4g.micro (dev) | $15 |
| Lambda | 무료 티어 (1M 요청) | $0-5 |
| API Gateway | 무료 티어 (1M 요청) | $0-3 |
| S3 + CloudFront | < 1GB 전송 | $1-2 |
| Cognito | < 50K MAU | $0 |
| CloudWatch | 기본 로그 | $3-5 |
| **합계** | | **$19-30/월** |

**비용 절감 팁:**

1. **AWS 프리 티어 활용** (신규 계정 12개월)
   - 750시간/월 t2.micro RDS
   - 1M Lambda 요청/월
   - 5GB S3 스토리지

2. **NAT Gateway 비용 절감** ($32/월):
   - S3/Secrets Manager 접근을 위한 VPC 엔드포인트 사용
   - 인터넷 게이트웨이를 사용하는 퍼블릭 서브넷의 Lambda (무료)

3. **CloudWatch Logs 최소화**:
   - 보관 기간 7일로 설정 (dev)
   - 고용량 API에 대한 로그 샘플링 사용

### 7.2 업그레이드 시점

**db.t4g.micro에서 업그레이드가 필요한 지표:**

1. **CPU > 80%** 가 5분 이상 지속
   → db.t4g.small로 업그레이드 (~$30/월)

2. **스토리지 > 15GB**
   → 할당 스토리지 증가 (10GB당 ~$2/월 추가)

3. **쿼리 응답 시간 > 500ms**
   → 읽기 전용 복제본 추가 또는 Aurora로 마이그레이션

4. **사용자 수 > 5,000 활성 사용자**
   → Aurora Serverless v2로 마이그레이션 (~$100/월)

### 7.3 비용 알림 (권장)

```typescript
// services/infrastructure/lib/monitoring-stack.ts
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';

export class MonitoringStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const costAlertTopic = new sns.Topic(this, 'CostAlertTopic');
    costAlertTopic.addSubscription(
      new subscriptions.EmailSubscription('admin@yourcompany.com')
    );

    new cloudwatch.Alarm(this, 'CostAlarm', {
      metric: new cloudwatch.Metric({
        namespace: 'AWS/Billing',
        metricName: 'EstimatedCharges',
        statistic: 'Maximum',
        dimensionsMap: { Currency: 'USD' },
      }),
      threshold: 50,
      evaluationPeriods: 1,
      alarmDescription: 'AWS 월 비용이 $50를 초과할 때 알림',
      actionsEnabled: true,
    }).addAlarmAction(new cloudwatch_actions.SnsAction(costAlertTopic));
  }
}
```

---

## 8. 대안: 프리시드 스타트업을 위한 Supabase

**즉시 출시**가 필요하고 **인프라 비용 $0**를 원한다면 Supabase로 시작하세요:

### 8.1 Supabase 무료 티어 혜택

| 기능 | 무료 티어 | 유료 (Pro) |
|------|----------|-----------|
| 데이터베이스 | 500MB PostgreSQL | 무제한 |
| 스토리지 | 1GB | 100GB |
| API 요청 | 무제한 | 무제한 |
| 인증 | 무제한 사용자 | 무제한 |
| 비용 | **$0/월** | $25/월 |

**백엔드 코드가 이미 Supabase SDK를 사용 중** - 코드 변경 불필요!

### 8.2 마이그레이션 경로: Supabase → AWS

**마이그레이션 시점:**
1. 데이터베이스 크기 > 400MB (한계 근접)
2. 시드 펀딩 확보 (>$50K)
3. 커스텀 AWS 통합 필요

**마이그레이션 단계:**
1. `pg_dump`를 사용하여 Supabase 데이터베이스 내보내기
2. AWS CDK 스택 배포 (RDS + Lambda)
3. `psql`을 사용하여 RDS로 데이터베이스 가져오기
4. 환경 변수 업데이트 (SUPABASE_URL → AWS_RDS_ENDPOINT)
5. DNS를 AWS API Gateway로 리다이렉트

**예상 마이그레이션 시간**: 2-4시간 (최소 다운타임)

### 8.3 스타트업을 위한 권장사항

비용 제약을 고려하여 ("스타트업이라서.. 비용 고려도 해줘"), 다음 접근 방식을 권장합니다:

**Phase 1 (MVP - 0-3개월):**
- **Supabase 무료 티어** 사용 ($0/월)
- 제품-시장 적합성 검증에 집중
- 최대 1,000명의 베타 사용자 지원

**Phase 2 (출시 - 3-12개월):**
- **AWS RDS db.t4g.micro**로 마이그레이션 ($15-30/월)
- 500MB 한계 도달 또는 시드 펀딩 확보 시
- 본 가이드의 CDK 스택을 사용하여 배포

**Phase 3 (성장 - 시리즈 A 이후):**
- **Aurora Serverless v2**로 업그레이드 ($100+/월)
- 활성 사용자 수 10,000명 초과 시
- CDK에서 한 줄만 변경: `DatabaseStack` → `DatabaseStackAurora`

---

## 9. 다음 단계

### 즉시 출시 (<$20/월 예산):
1. **Supabase 무료 티어 사용** - MVP를 위해 AWS를 완전히 건너뜀
2. **Vercel에 백엔드 배포** - 서버리스 함수용 무료 티어
3. **베타 사용자와 테스트** - 제품-시장 적합성 검증
4. **비용 모니터링** - 결제 알림 설정

### 펀딩 받은 스타트업 ($30-50/월 예산):
1. ✅ **AWS Dev 환경 배포** - 비용 최적화 RDS 사용 (db.t4g.micro)
2. ✅ **부하 테스트** - 성능 검증 (< 200ms p95)
3. ✅ **보안 감사** - 침투 테스트 (레드팀 이슈 먼저 수정!)
4. ✅ **Prod 배포** - 모니터링과 함께 운영 시작
5. ✅ **비용 알림 설정** - 월 지출 < $50 모니터링

### 성장 단계 (시리즈 A 펀딩):
1. **Aurora로 업그레이드** - 사용자 수 10,000명 이상일 때
2. **Multi-AZ 활성화** - 프로덕션 고가용성
3. **읽기 전용 복제본 추가** - 쿼리 성능 향상
4. **글로벌 CDN** - 엣지 로케이션을 사용하는 CloudFront

---

**문서 끝**
