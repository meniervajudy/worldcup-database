#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

games=$(awk -F, 'NR > 1 { printf "(%s, '\''%s'\'', '\''%s'\'', '\''%s'\'', %s, %s),", $1, $2, $3, $4, $5, $6 }' games.csv)
games=${games%,}

$PSQL "INSERT INTO teams(name)
SELECT team_name
FROM (
  SELECT winner AS team_name
  FROM (VALUES $games) AS game_data(year, round, winner, opponent, winner_goals, opponent_goals)
  UNION
  SELECT opponent AS team_name
  FROM (VALUES $games) AS game_data(year, round, winner, opponent, winner_goals, opponent_goals)
) AS unique_teams
ON CONFLICT (name) DO NOTHING;

INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals)
SELECT game_data.year, game_data.round, winner.team_id, opponent.team_id,
       game_data.winner_goals, game_data.opponent_goals
FROM (VALUES $games) AS game_data(year, round, winner, opponent, winner_goals, opponent_goals)
JOIN teams AS winner ON winner.name = game_data.winner
JOIN teams AS opponent ON opponent.name = game_data.opponent;"
