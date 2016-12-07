#!/bin/bash

INVALID_ANS="Invalid answer"
NO_COMMAND="Command not found"

ask_ans() {
  if   (( $# <= 1 )); then
    echo "Too few parameters"
    exit
  elif (( $# >= 2 )); then
    ret_var=$1
    message=$2
  fi

  while true; do
    echo -n "$message"" : "
    read ans

    eval "$ret_var=$ans"
  done
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
    echo -n "$message"" y/n : "
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

default_retries=5
install_with_retries() {
  if   [[ $# == 0 ]]; then
    echo "Too few parameters"
    exit
  elif [[ $# == 1 ]]; then
    package_name=$1
    retries=$default_retries
    retries_left=$default_retries
  elif (( $# >= 2 )); then
    package_name=$1
    retries=$2
    retries_left=$2
  fi

  while true; do
    echo "Installing ""$package_name"" package"
    arch-chroot "$mount_path" pacman --noconfirm -S $package_name
    if [[ $? == 0 ]]; then
      break
    else
      retries_left=$[$retries_left-1]
    fi

    if [[ $retries_left == 0 ]]; then
      echo "Package install failed ""$retries"" times"
      ask_yn change_name "Do you want to change package name before continuing retry?"

      if $change_name; then
        ask_new_name_end=false
        while ! $ask_new_name_end; do
          echo "Please enter new package name : "
          read package_name

          ask_if_correct ask_new_name_end
        done
      fi

      retries_left=$retries
    fi
  done
}

tell_press_enter() {
  echo "Press enter to continue"
  read
}

tell_read_note() {
  echo ""
  echo "===== IMPORTANT ====="
  echo "Please read over the setup note that this setup script has generated for you"
  echo "The setup note is stored as "$llsh_setup_note_path" in your system"
  echo ""
  echo "The setup note contains important information of the other helper scripts that have been generated for you"
  echo "====================="
  echo ""

  tell_press_enter
}

# ask_yn end "Testing yes or no"
ask_if_correct end

if $end; then
  echo "Recorded yes"
else
  echo "Recorded no"
fi

flip_ans end

if $end; then
  echo "Now recorded as yes"
else
  echo "Now recorded as no"
fi

comple
