#!/bin/bash

printf "You'll need to pay attention and be prompted for your sudo password at various portions of this installation...\n"

# ------------------------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------------------------
printf "Checking for hombrew...\n"
if ! command -v brew &> /dev/null; then
  printf "Homebrew not found! Installing Homebrew...\n"

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # If you want to use zsh then put them in ~/.zprofile
  # echo '# Set PATH, MANPATH, etc., for Homebrew.' >> ~/.zprofile
  # echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile

  # This should load brew so we can install stuff
  eval "$(/opt/homebrew/bin/brew shellenv)"

else
  printf " - Already satisfied\n"
fi
printf "\n"

printf "Checking for jq...\n"
if ! command -v jq &> /dev/null; then
  printf "jq not found! Installing jq...\n"
  brew install jq
  printf "jq and homebrew now installed you may need to restart your terminal to have access to them...\n"
else
  printf " - Already satisfied\n"
fi
printf "\n"

# ------------------------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------------------------
while read -r CATEGORY <&3; do
  CATEGORY_NAME=$(printf "%s" "$CATEGORY" | jq -r '.name')
  PROMPT=$(printf "%s" "$CATEGORY" | jq -r '.prompt // empty')

  if [[ ! -z "$PROMPT" ]]; then
    read -p "[$CATEGORY_NAME] $PROMPT (Y/n) " ANSWER
    case $ANSWER in 
	    [nN] )
	      printf "   Skipping...\n";
	      continue;
		    ;;
	    * ) ;;
    esac
  fi

  while read -r CONFIG <&4; do

    NAME=$(printf "%s" "$CONFIG" | jq -r '.name // empty')
    PROMPT=$(printf "%s" "$CONFIG" | jq -r '.prompt // empty')
    TEST=$(printf "%s" "$CONFIG" | jq -r '.test // empty')
    ACTIONS=$(printf "%s" "$CONFIG" | jq -r '.actions // empty')
    OPTIONS=$(printf "%s" "$CONFIG" | jq -r '.options // empty')

    printf " - $NAME..."

    # If we have a TEST evaluate it and if its true run the actions
    RUN_ACTIONS=true

    # If we have a test check if the conditions are met
    if [[ ! -z "$TEST" ]]; then
      if eval $TEST; then

        # If we detected something we need to change and have a prompt, then ask if the user wants to change it
        if [[ ! -z "$PROMPT" ]]; then
          printf "\n"
          read -p "   $PROMPT (Y/n) " ANSWER
          case $ANSWER in 
	          [nN] )
	            printf "   Skipping...\n";
	            RUN_ACTIONS=false
		          ;;
	          * ) ;;
          esac
        fi

      else
        printf " ...already satisfied!\n"
        RUN_ACTIONS=false
      fi
    else
      printf "\n"
    fi

    # Check if there's a set of options for a user to choose
    if [[ $RUN_ACTIONS = "true" ]] && [[ ! -z "$OPTIONS" ]]; then
      printf "\n"

      printf "\t0. Cancel\n"

      COUNT=1

      printf "%s" "$OPTIONS" | jq -c -r '.[] | tostring' | while read -r OPTION; do
        OPTION_NAME=$(printf "%s" "$OPTION" | jq -r '.name // empty')
        printf "\t%i. %s\n" "$COUNT" "$OPTION_NAME"
        (( COUNT++ ))
      done

      COUNT=$(printf "%s" "$OPTIONS" | jq length)

      printf "\n"

      CHOICE=-1
      while (( "$CHOICE" < "0" || "$CHOICE" > "$COUNT" )); do
        read -p "   Select an item from the list: " CHOICE
      done

      if [[ "$CHOICE" = "0" ]]; then
        RUN_ACTIONS=false
      else
        ACTIONS=$(printf "%s" "$OPTIONS" | jq -c -r ".[$CHOICE - 1].actions")
      fi
    fi

    if [ "$RUN_ACTIONS" = true ]; then
      printf "%s\n" "$ACTIONS" | jq -c -r '.[] | tostring' | while read -r ACTION; do
        eval $ACTION
      done
    fi
  done 4< <(printf "%s\n" "$CATEGORY" | jq -c -r '.configs[] | tostring')

  printf "\n\n"
done 3< <(jq -c -r '.[]' ./setup-mac.json)

exit

# Lots of these from here: https://github.com/mathiasbynens/dotfiles/blob/master/.macos
#
# Useful for Yabai
# System Preferences > Mission Control > Automatically rearrange Spaces based on most recent use
# defaults write com.apple.dock mru-spaces -bool false
