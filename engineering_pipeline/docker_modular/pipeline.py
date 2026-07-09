# pipeline.py

import os
import pandas as pd
from pathlib import Path

class UniversalETLPipeline:
    """
    Class: UniversalETLPipeline
    Description: A universal ETL pipeline for data extraction, transformation, and loading.
    不写死任何一张表的名字，而是动态读取外部YAML/Dict配置
    """

    def __init__(self, global_config: dict, data_dir: Path):
        self.global_settings = global_config['global_settings']
        self.data_dir = data_dir

    def extract(self, csv_name: str) -> pd.DataFrame:
        """
        Extract data from a CSV file.
        """
        csv_path = self.data_dir / csv_name
        print(f"Extracting data from {csv_path}")
        if not csv_path.exists():
            raise FileNotFoundError(f"CSV file {csv_path} does not exist")
        return pd.read_csv(csv_path)
    
    def transform(self, df: pd.DataFrame, expected_cols: list, critical_cols: list) -> pd.DataFrame:
        """
        Transform data using a specified function.
        """
        print(f"Transforming data")
        # Schema边界检验
        for col in expected_cols:
            if col not in df.columns:
                print(f"Column {col} not found in dataframe")
        
        for col in critical_cols:
            if col not in df.columns and df[col].isnull().any():
                null_count = df[col].isnull().sum()
                print(f"Critical column {col} has {null_count} null values")

        # Basic clean: 
        df = df.copy()
        str_cols = df.select_dtypes(include=['object']).columns
        for col in str_cols:
            df[col] = df[col].str.strip()  # 去除字符串列的前后空格, 它会自动清洗这一列的所有行

        return df
    
    def load(self, df: pd.DataFrame, target_table: str):
        """
        Load data into a target table.
        """
        print(f"Loading data into table {target_table}")
        
        schema = self.global_settings['schema']
        if_exits = self.global_settings['if_exists']
        print(f" loading finshed")

    def execute_table_job(self, table_key: str, table_config: dict):
        try:
            df_raw = self.extract(table_config['csv_name'])
            df_clean = self.transform(df_raw, table_config['expected_cols'], table_config['critical_cols'])
            self.load(df_clean, table_config['target_table'])
            print(f" Successfully processed table: {table_key}")
        except Exception as e:
            print(f"Error processing table {table_key}: {e}")