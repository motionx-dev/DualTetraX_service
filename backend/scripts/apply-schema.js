import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

console.log('🔧 Applying DualTetraX MVP Database Schema...\n');

// Read SQL file
const schemaPath = join(__dirname, '../../schema-mvp.sql');
const sqlContent = readFileSync(schemaPath, 'utf-8');

// Split by semicolons but preserve them in statements
const statements = sqlContent
  .split(';')
  .map(s => s.trim())
  .filter(s => s.length > 0 && !s.startsWith('--'))
  .map(s => s + ';');

console.log(`📄 Found ${statements.length} SQL statements\n`);

async function applySchema() {
  let successCount = 0;
  let errorCount = 0;

  for (let i = 0; i < statements.length; i++) {
    const statement = statements[i];

    // Skip comments and empty statements
    if (statement.trim().startsWith('--') || statement.trim() === ';') {
      continue;
    }

    // Extract operation type for logging
    const opMatch = statement.match(/^(CREATE|ALTER|DROP|INSERT|UPDATE|DELETE|DO)/i);
    const operation = opMatch ? opMatch[1].toUpperCase() : 'EXECUTE';

    try {
      const { error } = await supabase.rpc('exec_sql', { sql: statement });

      if (error) {
        // Try alternative method using REST API
        const response = await fetch(`${supabaseUrl}/rest/v1/rpc/exec_sql`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseServiceKey,
            'Authorization': `Bearer ${supabaseServiceKey}`,
          },
          body: JSON.stringify({ query: statement }),
        });

        if (!response.ok) {
          // Fallback: use the SQL editor endpoint
          const { data, error: execError } = await supabase
            .from('_sql')
            .select('*')
            .sql(statement);

          if (execError) {
            throw execError;
          }
        }
      }

      successCount++;
      process.stdout.write(`✓`);
      if ((i + 1) % 50 === 0) process.stdout.write('\n');

    } catch (err) {
      errorCount++;
      console.error(`\n❌ Error in statement ${i + 1}:`, err.message);
      console.error(`   Statement: ${statement.substring(0, 100)}...`);
    }
  }

  console.log('\n\n' + '='.repeat(50));
  console.log(`✅ Schema application complete!`);
  console.log(`   Success: ${successCount} statements`);
  console.log(`   Errors:  ${errorCount} statements`);
  console.log('='.repeat(50));

  if (errorCount > 0) {
    console.log('\n⚠️  Some statements failed. This may be normal if:');
    console.log('   - Tables already exist');
    console.log('   - Policies already exist');
    console.log('   - Functions already exist');
    console.log('\nPlease verify in Supabase Table Editor.');
  }

  process.exit(errorCount > 0 ? 1 : 0);
}

applySchema().catch(err => {
  console.error('\n❌ Fatal error:', err);
  process.exit(1);
});
