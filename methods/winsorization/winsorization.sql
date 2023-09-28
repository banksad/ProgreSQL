-- Checking and then adding new columns for outlier weights, Winsorized return, and a flag indicating whether a row was Winsorized
-- Check and add o_weight column if it doesn't exist
DO $$
BEGIN
    BEGIN
        ALTER TABLE winsorize_example ADD COLUMN o_weight NUMERIC;
    EXCEPTION
        WHEN duplicate_column THEN -- Do nothing, column already exists
    END;
END $$;

-- Check and add k_value column if it doesn't exist
DO $$
BEGIN
    BEGIN
        ALTER TABLE winsorize_example ADD COLUMN k_value NUMERIC;
    EXCEPTION
        WHEN duplicate_column THEN -- Do nothing, column already exists
    END;
END $$;

-- Check and add modified_return column if it doesn't exist
DO $$
BEGIN
    BEGIN
        ALTER TABLE winsorize_example ADD COLUMN modified_return NUMERIC;
    EXCEPTION
        WHEN duplicate_column THEN -- Do nothing, column already exists
    END;
END $$;

-- Check and add winsorization_flag column if it doesn't exist
DO $$
BEGIN
    BEGIN
        ALTER TABLE winsorize_example ADD COLUMN winsorization_flag TEXT;
    EXCEPTION
        WHEN duplicate_column THEN -- Do nothing, column already exists
    END;
END $$;

-- Calculate the mean return for each cell. This is used to calculate the threshold (k_value) for Winsorization.
WITH CellMean AS (
    SELECT
        cell,
        AVG(return) AS y_bar_h
    FROM
        winsorize_example
    GROUP BY
        cell
)

-- Update the k_value and modified_return columns based on the Winsorization threshold
UPDATE winsorize_example
SET 
    -- Calculate the threshold (k_value) for each row based on its cell's mean return and its a_weight
    k_value = CellMean.y_bar_h + (3000 / (a_weight - 1)),
    
    -- Calculate the modified return based on the Winsorization threshold.
    -- If the return exceeds the threshold, it's replaced with a Winsorized value.
    modified_return = CASE 
        WHEN return > k_value THEN (1.0 / (a_weight * g_weight)) * return + (1 - (1.0 / (a_weight * g_weight))) * k_value
        ELSE return
    END
FROM 
    CellMean
WHERE 
    winsorize_example.cell = CellMean.cell;

-- Update the o_weight (outlier weight) and winsorization_flag columns
UPDATE winsorize_example
SET 
    -- If a return exceeds its threshold, set its outlier weight to the ratio of its modified return to its original return. Otherwise, set it to 1.
    o_weight = CASE 
        WHEN return > k_value THEN modified_return / return
        ELSE 1
    END,
    
    -- If a return exceeds its threshold, flag it as 'W' (Winsorized). Otherwise, flag it as 'NW' (Not Winsorized).
    winsorization_flag = CASE 
        WHEN return > k_value THEN 'W'
        ELSE 'NW'
    END;
