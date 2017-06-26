#!/bib/bash
# The following section is copied from setup.sh with slight modification
# It was last copied over from setup.sh on 2017-06-26

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
  useradd -m "$user_name" -G users,wheel,rfkill
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
