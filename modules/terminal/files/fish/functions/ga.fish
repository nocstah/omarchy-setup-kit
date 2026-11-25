function ga --description 'Create a git worktree and branch, then cd into it'
    if test -z "$argv[1]"
        echo "Usage: ga [branch name]"
        return 1
    end

    set -l branch $argv[1]
    set -l base (path basename $PWD)
    set -l wt_path "../$base--$branch"

    # Omarchy's bash version runs `mise trust` and `cd` even when the worktree
    # fails to appear, which then cds into a path that does not exist.
    git worktree add -b $branch $wt_path; or return 1

    mise trust $wt_path
    cd $wt_path
end
