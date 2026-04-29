import pandas as pd
import sys

def load_csv_safely(file_path : str) -> pd.DataFrame:
    
    candidate_encodings = ['utf-8', 'latin-1', 'iso-8859-1', 'cp1252']

    for encoding in candidate_encodings:
        try:
            df = pd.read_csv(file_path, encoding=encoding)
            print(f"✅ 成功加载 CSV 文件 (所用编码: {encoding})")
            return df
        except UnicodeDecodeError:
            print(f"⚠️ 失败: 无法使用 {encoding} 解码文件，尝试下一个编码...")
        except Exception as e:
            print(f"❌ 加载 CSV 文件时发生错误: {e}")
            sys.exit(1)
        except Exception as e:
            ## 处理其他异常
            print(f"❌ 加载 CSV 文件时发生错误: {e}")
            sys.exit(1)
    
    # 如果所有编码都尝试失败，则直接退出脚本
    print("❌ 所有编码尝试失败，请检查文件编码")
    sys.exit(1)

# 测试代码块
if __name__ == "__main__":
    test_file = "olist_analysis/raw_data/olist_customers_dataset.csv" 
    df = load_csv_safely(test_file)
    print(df.head())

