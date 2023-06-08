#! /bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

USER_LOGIN() {
  # Prompt for username
  echo "Enter your username:"
  read USERNAME

  # Lookup for user in database
  USERNAME_QUERY_RESULT=$($PSQL "SELECT * FROM users WHERE username ILIKE '$USERNAME';")

  # Check if user found
  if [[ -z $USERNAME_QUERY_RESULT ]]
  then

    # Create new user if user not found
    CREATE_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME');")

    if [[ $CREATE_USER_RESULT="INSERT 0 1" ]]
    then

      # Greet New User
      echo "Welcome, $USERNAME! It looks like this is your first time here."
    fi
  else
    echo $USERNAME_QUERY_RESULT | while IFS="|" read USERNAME GAMES_PLAYED BEST_GAME USER_ID
    do

      # Greet Existing User
      echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    done
  fi
  INIT
}

INIT() {

  # Generate a random number
  # SECRET_NUMBER=$((1+$RANDOM%1000))
  SECRET_NUMBER=2

  # Initialise number of guesses
  NUM_GUESSES=0

  # Read first guess
  READ_GUESSES "Guess the secret number between 1 and 1000:"
}

READ_GUESSES() {
  if [[ ! -z $1 ]]
  then
    echo $1
  fi
  read GUESS

  # Check Input
  CHECK_INPUT
}

CHECK_INPUT() {
 re='^[0-9]+$'
  if [[ ! $GUESS =~ $re ]]
  then
    READ_GUESSES "That is not an integer, guess again:"
  else
    (( NUM_GUESSES++ ))
    COMPARE_NUMBER
  fi
}

COMPARE_NUMBER() {
  
  # Compare secret number with guess
  if [[ $GUESS -gt $SECRET_NUMBER ]]
  then 
    READ_GUESSES "It's lower than that, guess again:"
  else
    if [[ $GUESS -lt $SECRET_NUMBER ]]
    then
      READ_GUESSES "It's higher than that, guess again:"
    else
      UPDATE_DATABASE
    fi
  fi
}

UPDATE_DATABASE() {
  USERNAME_QUERY_RESULT=$($PSQL "SELECT * FROM users WHERE username ILIKE '$USERNAME';")
  if [[ ! -z $USERNAME_QUERY_RESULT ]]
  then
    echo $USERNAME_QUERY_RESULT | while IFS="|" read USERNAME GAMES_PLAYED BEST_GAME USER_ID
    do
      if [[ -z $GAMES_PLAYED ]]
      then
        GAMES_PLAYED=0
      fi
      if [[ -z $BEST_GAME ]]
      then
        BEST_GAME=1001
      fi
      # Update database
      if [[ $BEST_GAME -gt $NUM_GUESSES ]]
      then 
        UPDATE_RESULT=$($PSQL "
        UPDATE users 
        SET (games_played, best_game) = ($GAMES_PLAYED + 1, $NUM_GUESSES)
        WHERE username = '$USERNAME'")
      else
        UPDATE_RESULT=$($PSQL "
        UPDATE users 
        SET games_played = $GAMES_PLAYED + 1
        WHERE username = '$USERNAME'")
      fi

      # Echo winning message
      if [[ $UPDATE_RESULT="UPDATE 1" ]]
      then
        echo -e "You guessed it in $NUM_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
      fi
    done
  fi
}

USER_LOGIN