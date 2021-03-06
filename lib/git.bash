#  Copyright (C) 2021 Benjamin Stürz
#
#  This file is part of the accounthing project.
#  
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Git versioning support
# External Dependencies:
# - git

# git_commit_msg is now defined in the config
git_need_commit=0


if [ "${enable_git}" = true ]; then

   if [ -z "${GIT}" ]; then
      GIT="$(which git)"
      [ -z "${GIT}" ] && error "git is not installed."
   fi

   # Commits to the git repo.
   git_commit() {
      [ "${git_need_commit}" = 0 ] && return

      mkdir -p "${datadir}"
      pushd "${datadir}" >/dev/null || return 1

      # If there is no git repo
      if [ ! -d .git ]; then
         "${GIT}" init -q || return 1
      fi

      "${GIT}" add . || return 1
      echo "${git_commit_msg}" | "${GIT}" commit -qF - || return 1
      popd >/dev/null || return 1

      [[ ${git_autopush} = true ]] && git_push

      git_reset_msg
      git_need_commit=0
   }

   # Prints the ID of the last commit
   git_get_commit() {
      pushd "${datadir}" >/dev/null || return 1
      git describe --always 2>/dev/null
      popd >/dev/null || return 1
   }

   # Reads commits into an array
   # Arguments:
   #   $1 - out_array
   git_read_commits() {
      local log
      [[ -d ${datadir}/.git ]] || return 1
      pushd "${datadir}" >/dev/null || return 1
      log="$(git log --format="format:%h,%s")"
      mapfile -t "$1" <<<"${log}"
      popd >/dev/null || return 1
   }

   # Get the commit message from a commit.
   # Arguments:
   #   $1 - commit hash
   #   $2 - format string (See: man git-show)
   git_show_message() {
      pushd "${datadir}" >/dev/null || return 1
      git show --no-patch --format="format:$2" "$1"
      popd >/dev/null || return 1
   }

   # Run a git command.
   # Arguments:
   #   $... - git args
   git_do() {
      pushd "${datadir}" >/dev/null || return 1
      git "$@"
      popd >/dev/null || return 1
   }

   # Arguments:
   #   $1 - out
   git_get_remotes() {
      local name URI
      pushd "${datadir}" >/dev/null || return 1
      for name in $(git remote); do
         URI="$(LC_ALL=C git remote show -n "${name}" \
            | grep 'Fetch URL' \
            | sed 's/^\s*Fetch\s\+URL\s*:\s*//')"
         eval "${1}+=('${name}' '${URI}')"
      done
      popd >/dev/null || return 1
   }

   git_push_all() {
      local remote branch
      pushd "${datadir}" >/dev/null || return 1
      branch="$(git branch --show-current)"
      for remote in $(git remote); do
         git push "${remote}" "${branch}"
      done
      popd >/dev/null || return 1
   }

   git_push() {
      local branch
      pushd "${datadir}" >/dev/null || return 1
      branch="$(git branch --show-current)"
      git push "$1" "${branch}"
      popd >/dev/null || return 1
   }

else

   git_commit() {
      :
   }

   git_push() {
      :
   }

   git_get_commit() {
      return 1
   }

   git_read_commits() {
      return 1
   }  

fi


# Append a string to the commit message.
# Arguments:
#   $1 - string
git_append_msg() {
   git_commit_msg="$(printf "%s\n%s" "${git_commit_msg}" "$1")"
   git_need_commit=1
}

git_reset_msg() {
   git_commit_msg=""
   [[ ${git_commit_header} ]] && git_commit_msg="${git_commit_header}\n"
}


git_reset_msg
