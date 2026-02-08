# 코드 스타일 가이드

## 핵심 원칙

1. **띄어쓰기는 2칸 공백**
2. **주석은 최소화하고, 주석은 영어로**
3. **읽기 쉬운 코드로 작성**

## 기본적인 코드 스타일

### if () 문
if () 문은 아래와 같이 처리문이 한줄이 되더라도 무조건 {} 을 사용한다.

```
if (조건) {
  처리1;
} else {
  처리2;
}
```

### 읽기 편한 코드
다음과 같이 선언문, 대입문, 조건문, 반복문 등을 그룹화 하여 단락을 짓는다.

```
int32_t temp = 10;
std::string name = "홍길동";

temp = rans() % 100;

if (temp > 20) {
  name = "홍길순";
}

int32_t sum = 0;

for (int32_t i = 0; i < 100; i++) {
  sum = sum + i;

  if (temp > 20) {
    sum = sum + 2;
  } else {
    if (sum > 100) {
      sum = sum + 3;
    } else {
      sum = sum + 4;
    }
  }

  if (sum > 100) {
    break;
  }
}

```

### 함수 인자 및 로그들은 가능한 한 줄 표시
해상도가 높은 모니터를 사용하기 때문에 너무 길지 않은 선(200자에서 250자 이내)에서 한 줄 표시

```
void 함수(int32_t 인자1, int32_t 인자2, int32_t 인자3, std::string strudunt_name, std::string strudunt_address);
```

```
printf("인자1: %d, 인자2: %d, 인자3: %d, strudunt_name: %s, strudunt_address: %s\n", 인자1, 인자2, 인자3, strudunt_name.c_str(), strudunt_address.c_str());
```


## C++ 스타일
### 변수 선언과 조건문 사이의 빈 줄
변수를 선언하고 바로 조건문이 오는 경우, 선언문과 조건문 사이에 빈 줄을 넣는다.
또한, 함수의 마지막 return 문 앞에도 빈 줄을 넣어 가독성을 높인다.

**나쁜 예:**
```cpp
std::string get_file_path() const
{
  if (is_streaming_ == true) {
    auto camera = get_camera();
    if (camera) {
      return camera->path;
    }
  }
  return default_path_;
}
```

**좋은 예:**
```cpp
std::string get_file_path() const
{
  if (is_streaming_ == true) {
    auto camera = get_camera();

    if (camera) {
      return camera->path;
    }
  }

  return default_path_;
}
```

### class 선언

1. 생성자와 소멸자는 다른 함수들과 따로 정의
2. public, protected, private 순의로 정의
3. 함수를 먼저 정의하고, 그 이후에 변수를 정의
   - 함수: public, protected, private
   - 변수: public, protected, private
4. 함수 중 protected 및 private는 do_, on_ 등 prefix를 붙임
5. 멤벼 변수는 변수 이름 끝에 _ 를 붙임
6. 함수는 소문자로, 동사가 먼저 옴
   - set_xxx
   - process_xxx
7. 변수는 소문자로 길지 않은 선에서 의미가 있게 정의
   - bool --> is_xxx_, enable_xxx_ 등

```
class 클래스명 {
public:
  클래스명();
  ~클래스명();

public:
  void 함수1();

protected:
  void do_함수2();

private:
  void do_함수3();

public:
  int32_t 변수1;

protected:
  int32_t 변수2;

private:
  int32_t 변수3;
};
```