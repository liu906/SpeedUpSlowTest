```# deps
pip install requests

# auth (use your Personal Access Token)
export GITHUB_TOKEN="ghp_your_token"

# run (Best match by default)
python fetch_slow_tests_gql.py \
  --out data/slow_test_issues.csv \
  --max 500 \
  --q '"slow test" is:issue is:closed comments:>3 linked:pr' \
  --min_stars 5
  ```
