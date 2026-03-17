# Outputs section heading
#
# Usage:
#
#     output_section "Application tasks"
#
output_section() {
  local indentation="----->"
  echo "${indentation} $1"
}

# Outputs log line
#
# Usage:
#
#     output_line "Cloning repository"
#
output_line() {
  local spacing="      "
  echo "${spacing} $1"
}

# Outputs a warning in red
#
# Usage:
#
#     output_warning "Something went wrong"
#
output_warning() {
  local spacing="      "
  echo -e "${spacing} \e[31m$1\e[0m"
}

# Outputs to stderr for debugging
#
# Usage:
#
#     output_stderr "Debug info"
#
output_stderr() {
  # Outputs to stderr in case it is inside a function so it does not
  # disturb the return value. Useful for debugging.
  echo "$@" 1>&2;
}

# Pipe processor for indenting command output
#
# Usage:
#
#     command | output_indent
#
output_indent() {
  while read LINE; do
    echo "       $LINE" || true
  done
}
