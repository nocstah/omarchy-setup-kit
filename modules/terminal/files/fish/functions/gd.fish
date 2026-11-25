function gd --description 'Remove the worktree and branch you are standing in'
    gum confirm "Remove worktree and branch?"; or return 1

    set -l cwd $PWD
    set -l worktree (path basename $cwd)

    # Split on the FIRST `--`; a branch name may contain more of them.
    set -l parts (string split -m1 -- -- $worktree)

    # Protect against accidentally nuking a non-worktree directory: without a
    # `--` in the name this is not one of ours.
    if test (count $parts) -ne 2
        echo "Not a worktree directory: $worktree"
        return 1
    end

    set -l root $parts[1]
    set -l branch $parts[2]

    cd "../$root"; or return 1
    git worktree remove $cwd --force; or return 1
    git branch -D $branch
end
