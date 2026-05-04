SELECT
  job_id,
  creation_time,
  -- 使用 SAFE_OFFSET 防止越界
  job_stages[SAFE_OFFSET(0)].records_written AS rows_loaded,
  total_bytes_processed,
  state,
  error_result.message AS error_msg
FROM
  `region-us`.INFORMATION_SCHEMA.JOBS_BY_USER
WHERE
  creation_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
  AND job_type = 'LOAD'  -- 确保只看加载任务
ORDER BY
  creation_time DESC;