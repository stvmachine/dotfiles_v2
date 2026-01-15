# NVM setup for Fish shell
if command -qs brew
    function nvm
       bass source (brew --prefix nvm)/nvm.sh --no-use ';' nvm $argv
    end

    # Use default node version
    if test -d ~/.nvm
        nvm use default --silent 2>/dev/null
    end

    # Trigger 'nvm use' if .nvmrc or .node-version exists in the folder
    function __check_nvm --on-variable PWD --description 'Do nvm stuff'
      # Check for .nvmrc first, then .node-version
      set -l version_file ""
      if test -f .nvmrc
        set version_file .nvmrc
      else if test -f .node-version
        set version_file .node-version
      end

      if test -n "$version_file"
        set node_version (nvm version)
        set nvmrc_node_version (nvm version (cat $version_file))

        if [ $nvmrc_node_version = "N/A" ]
          nvm install (cat $version_file)
        else if [ $nvmrc_node_version != $node_version ]
          nvm use (cat $version_file)
        end

        # Testing if ~/bin folder exists
        if test -d ~/bin
          echo "Dir ~/bin exists"
        else 
          mkdir ~/bin
          fish_add_path ~/bin
        end
        
        # link node to usr/local/bin for apps that doesn't work well with nvm as xcode
        rm -f ~/bin/node
        rm -f ~/bin/npm
        ln -s "$(which node)" ~/bin/node
        ln -s "$(which npm)" ~/bin/npm
      end
    end

    __check_nvm
end

set -Ux NODE_OPTIONS "--max-old-space-size=4096"