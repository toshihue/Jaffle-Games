/Users/elias/.local/bin/dbt lint --fix
cp -f ./setup/mart_monetization_modified.sql ./models/marts/finance/mart_monetization.sql
/Users/elias/.local/bin/dbt build --target prod --manage-state

git reset --hard HEAD

# Bump the dev target/schema to the next increment so each run gets a fresh schema
CURRENT=$(grep -oE 'dev_cool_guy_[0-9]+' profiles.yml | grep -oE '[0-9]+$' | head -1)
NEXT=$((CURRENT + 1))
sed -i '' -E "s/dev_cool_guy_${CURRENT}:/dev_cool_guy_${NEXT}:/; s/DBT_EDEFARIA_JAFFLE_GAMES_COOL_GUY_${CURRENT}\$/DBT_EDEFARIA_JAFFLE_GAMES_COOL_GUY_${NEXT}/" profiles.yml
echo "Bumped dev_cool_guy_${CURRENT} -> dev_cool_guy_${NEXT}"

/Users/elias/.local/bin/dbt clean
/Users/elias/.local/bin/dbt debug
/Users/elias/.local/bin/dbt debug --target dev_cool_guy_${NEXT}
/Users/elias/.local/bin/dbt deps
/Users/elias/.local/bin/dbt test --resource-types unit_test