#!/bin/bash
# The following section is copied from setup.sh with slight modification
# It was last copied over from setup.sh on 2017-06-26

INVALID_ANS="Invalid answer"
NO_COMMAND="Command not found"

groups="users,rfkill"

ask_ans() {
  if   (( $# <= 1 )); then
    echo "Too few parameters"
    exit
  elif (( $# >= 2 )); then
    ret_var=$1
    message=$2
  fi

  echo -ne "$message"" : "
  read ans

  eval "$ret_var=$ans"
}

ask_yn() {
  if   (( $# <= 1 )); then
    echo "Too few parameters"
    exit
  elif (( $# >= 2 )); then
    ret_var=$1
    message=$2
  fi

  while true; do
    echo -ne "$message"" y/n : "
    read ans
    if   [[ $ans == "y" ]]; then
      eval "$ret_var=true"
      break
    elif [[ $ans == "n" ]]; then
      eval "$ret_var=false"
      break
    else
      echo -e $INVALID_ANS
    fi
  done
}

ask_if_correct() {
  ask_yn $1 "Is this correct?"
}

comple() {
  if $(eval echo '$'$1); then
    eval "$2=false"
  else
    eval "$2=true"
  fi
}

flip_ans() {
  if $(eval echo '$'$1); then
    eval "$1=false"
  else
    eval "$1=true"
  fi
}

default_wait=1
wait_and_clear() {
  if [[ $# == 0 ]]; then
    sleep $default_wait
  else
    sleep $1
  fi
  clear
}

tell_press_enter() {
  echo "Press enter to continue"
  read
}

echo "User setup"
echo ""

while true; do
  ask_end=false
  while ! $ask_end; do
    ask_ans user_name "Please enter the user name"
    echo "You entered : " $user_name
    ask_if_correct ask_end
  done

  echo "Adding user"
  useradd -m "$user_name" -G "$groups"
  if [[ $? == 0 ]]; then
    break
  else
    echo "Failed to add user"
    echo "Please check whether the user name is correctly specified and if acceptable by the system"

    tell_press_enter
  fi
done

while true; do
  echo "Setting password for user : " $user_name

  passwd "$user_name"
  if [[ $? == 0 ]]; then
    break
  else
    echo "Failed to set password"
    echo "Please repeat the procedure"

    tell_press_enter
  fi
done

echo "User : " $user_name " added"
