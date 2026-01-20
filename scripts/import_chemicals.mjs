import fs from 'fs/promises';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL || 'https://qwhcenznfgxsptkagqqw.supabase.co';
const supabaseKey = process.env.SUPABASE_KEY;
if (!supabaseKey) {
  console.error('Missing SUPABASE_KEY environment variable.');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function load() {
  const raw = await fs.readFile(new URL('../chemicals.json', import.meta.url), 'utf8');
  return JSON.parse(raw);
}

async function run() {
  const data = await load();
  console.log(`Importing ${data.length} chemicals into Supabase...`);

  const batchSize = 50;
  for (let i = 0; i < data.length; i += batchSize) {
    const batch = data.slice(i, i + batchSize).map(item => ({
      id: item.id || undefined,
      name: item.name,
      short_description: item.shortDescription,
      uses: item.uses,
      precautions: item.precautions,
      mixing_note: item.mixingNote,
      sds_url: item.sdsURL
    }));

    const { error } = await supabase.from('chemicals').insert(batch);
    if (error) {
      console.error('Insert error on batch', i / batchSize, error);
      process.exit(1);
    }
    console.log(`Inserted batch ${i / batchSize + 1} (${batch.length} rows)`);
  }

  console.log('Import complete.');
}

run().catch(err => { console.error(err); process.exit(1); });
