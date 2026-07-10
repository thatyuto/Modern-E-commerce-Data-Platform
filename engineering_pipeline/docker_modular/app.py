import yaml
import os
from pathlib import Path
from pipeline import UniversalETLPipeline

def main():
    # 动态锁定容器或本地的当前工作路径
    BASE_DIR = Path(__file__).resolve().parent
    RAW_DATA_DIR = BASE_DIR / "raw_data"
    CONFIG_PATH = BASE_DIR / "config.yaml"
    DB_PATH = BASE_DIR / "olist_warehouse.db"

    print("_________ETL Pipeline Started_______")

    # step 1:
    with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)
    
    # step 2:
    pipeline_engine = UniversalETLPipeline(
        global_config=config, 
        data_dir=RAW_DATA_DIR,
        db_path=DB_PATH
    )

    # step 3:
    for table_key, table_config in config['tables'].items():
        pipeline_engine.execute_table_job(table_key, table_config)

    print("_________ETL Pipeline Finished_______")

if __name__ == "__main__":
    main()
