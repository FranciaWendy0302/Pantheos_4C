-- Add character_class column to support multiple classes
-- Run this to update your existing database

-- For characters table (if using MySQL/Node.js server)
ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS character_class VARCHAR(50) DEFAULT 'Swordsman';

-- Update existing characters to have Swordsman class
UPDATE characters 
SET character_class = 'Swordsman' 
WHERE character_class IS NULL OR character_class = '';

-- Add index for faster class queries
CREATE INDEX IF NOT EXISTS idx_character_class ON characters(character_class);

-- Verify the change
SELECT id, nickname, character_class, level FROM characters LIMIT 10;
