#compdef conda
#description:conda package manager
#
# ZSH Completion for conda (http://conda.pydata.org/)
#
# Author: Valentin Haenel <valentin@haenel.co>  (https://github.com/esc/)
# Licence: WTFPL (http://sam.zoy.org/wtfpl/)
# Version: 0.6-dev
# Homepage: https://github.com/esc/conda-zsh-completion
# Demo: https://asciinema.org/a/16516
#
# This completion depends on Python for a json parser, sorry. Unfortunately
# there is no such thing in zsh (yet).
#
# To use this completion drop it somewhere in you '$fpath', e.g.:
#
#     $ git clone $CLONEURL
#     $ fpath+=$PWD/conda-zsh-completion
#     $ compinit conda
#
# To activate the completion cache for packages, add the following to your
# '.zshrc':
#
#     zstyle ':completion::complete:*' use-cache 1
#
# To forcefully clean the completion cache, look in '~/.zcompcache' and remove
# file starting with 'conda_'.
#
# When developing, you can use the following to reload the completion after
# having modified it:
#
#    $ unfunction _conda && autoload -U _conda
#
# Please report any issues at:
# https://github.com/esc/conda-zsh-completion/issues
#
# CHANGELOG
# ---------
#
# * v0.6
#
#   * 
#
# * v0.5
#
#   * conda-env can now be completed
#   * conda-build can now be completed
#
# * v0.4
#
#   * conda info can complete available packages
#   * conda install and create have rudimentary package version completion
#   * remove caching for local package list, it's fast enough
#   * conda remove and update are aware of -n or similar and complete only
#     packages in the given environment
#   * list of packages excludes those installed with pip
#
# * v0.3
#
#   * overhaul of the completion for config
#
#     * complete only existing keys
#     * complete only existing values
#     * differentiate between list and boolean config
#     * reader and writer options mutually exclusive
#     * complete multiple keys for --get
#
#   * -n,--name and -p,--prefix are now mutually exclusive
#
# * v0.2
#
#   * completion cache for packages
#   * complete all channels defined in .condarc
#
# * v0.1
#
#   * inital release
#
# TODO
# ----
#
# * Subcommand grouping is still alpha.
# * Example of activating cache only for conda completion
# * Make cache policy configurable
# * Completion for version numbers is rudimentary:
#   only 'install' can complete them and only for a single '=' sign
# * Configuration for external commands: only build and env supported
# * Properly handle package specs on the command line
# * Don't continue to complete options once -- is given
# * None of the commands are aware of channels

local state line context
local -A opt_args

__conda_envs(){
    local -a envs
    envs=($( conda info -e | sed "1,2d" | cut -f1 -d' '))
    _describe -t envs 'conda environments' envs
}

__conda_packages_installed(){
    local -a installed_packages option environment additional_message
    # check for command line overrides
    [[ -n "$1" ]] && option="$1"
    [[ -n "$2" ]] && environment="$2"
    installed_packages=($( conda list --no-pip $option $environment | sed 1,2d | cut -f1 -d' ' ))
    [[ -n $option ]] && [[ -n $environment ]] && additional_message=" in environment: '$environment'"
    _describe -t installed_packages "installed packages$additional_message" installed_packages
}

__conda_package_available(){
    zstyle ":completion:${curcontext}:" cache-policy __conda_caching_policy
    local -a available_packages
    if _cache_invalid conda_available_packages || ! _retrieve_cache conda_available_packages ; then
        available_packages=($(conda search --use-index-cache --json |
        python -c "
import json, sys
parsed = json.load(sys.stdin)
for k in parsed.keys():
    print(k)
        "))
        _store_cache conda_available_packages available_packages
    fi
    print -l $available_packages

}

__describe_conda_package_available(){
    local -a available_packages
    available_packages=($( __conda_package_available))
    _describe -t available_packages 'available packages' available_packages
}

__conda_existing_config_keys(){
    local -a config_keys
    config_keys=($(conda config --json --get |
        python -c "
import json, sys
keys = json.load(sys.stdin)['get'].keys()
for k in keys:
    print(k)
        "))
    print -l $config_keys
}

__conda_describe_existing_config_keys(){
    local -a config_keys
    config_keys=($( __conda_existing_config_keys ))
    if [ "${#config_keys}" == 0 ] ; then
        _message "no keys found!"
    else
        _describe -t config_keys 'existing configuration keys' config_keys
    fi
}

__conda_describe_existing_list_config_keys(){
    local -a config_keys existing_list_config_keys
    config_keys=($( __conda_existing_config_keys ))
    existing_list_config_keys=()
    for k in $config_keys; do
        if (( ${__conda_list_config_keys[(I)$k]} )) ; then
            existing_list_config_keys+=$k
        fi
    done
    if [ "${#existing_list_config_keys}" == 0 ] ; then
        _message "no keys found!"
    else
        _describe -t existing_list_config_keys 'existing list configuration keys' existing_list_config_keys
    fi
}

__conda_existing_config_values(){
    local -a config_values search_term
    search_term="$1"
    config_values=($(conda config --json --get "$search_term" 2> /dev/null |
        python -c "
import json, sys
try:
    values = json.load(sys.stdin)['get']['$search_term']
    for v in values:
        print(v)
except KeyError:
    pass
except ValueError:
    pass
        "))
    print -l $config_values
}

__conda_describe_existing_config_values(){
    local -a config_values search_term
    search_term="$1"
    config_values=($( __conda_existing_config_values $search_term ))
    if [ "${#config_values}" == 0 ] ; then
        _message "no values found for '$search_term'!"
    else
        _describe -t config_values 'configuration values' config_values
    fi
}

__conda_describe_boolean_config_values(){
    local -a config_values
    config_values=(True False)
    _describe -t config_values 'boolean configuration values' config_values
}

__conda_channels(){
    local -a channels
    channels=($( __conda_existing_config_values "channels" ))
    channels+=(system)
    _describe -t channels 'conda channels' channels
}

local -a __conda_boolean_config_keys __conda_list_config_keys __conda_config_keys

__conda_boolean_config_keys=(
    'add_binstar_token'
    'always_yes'
    'allow_softlinks'
    'changeps1'
    'use_pip'
    'offline'
    'binstar_upload'
    'binstar_personal'
    'show_channel_urls'
    'allow_other_channels'
    'ssl_verify'
    )

__conda_list_config_keys=(
    'channels'
    'disallow'
    'create_default_packages'
    'track_features'
    'envs_dirs'
    )

__conda_config_keys=($__conda_boolean_config_keys $__conda_list_config_keys)

__conda_describe_boolean_config_keys(){
    _describe -t __conda_boolean_config_keys 'boolean keys' __conda_boolean_config_keys
}

__conda_describe_list_config_keys(){
    _describe -t __conda_list_config_keys 'list keys' __conda_list_config_keys
}

__conda_describe_config_keys(){
    _describe -t __conda_config_keys 'conda configuration keys' __conda_config_keys
}

#__conda_package_specs=('<'  '>' '<=' '>=' '==' '!=')
__conda_package_specs=('=')

__conda_describe_package_specs(){
    _describe -t __conda_package_specs 'conda package specs' __conda_package_specs
}

__conda_describe_package_version(){
    local -a current_package versions
    current_package="$1"
    versions=($( conda search --json --use-index-cache $current_package | python -c "
import json,sys
try:
    versions = set((e['version'] for e in json.load(sys.stdin)['$current_package']))
    for v in versions:
        print(v)
except KeyError:
    pass
    "))
    _describe -t versions "$current_package version" versions
}

__conda_commands(){
    local -a package maint environment help config special
    package=(
        search:'Search for packages and display their information.'
        install:'Install a list of packages into a specified conda environment.'
    )
    maint=(
        update:'Update conda packages.'
        clean:'Remove unused packages and caches.'
    )
    environment=(
        info:'Display information about current conda install.'
        create:'Create a new conda environment from a list of specified packages.'
        list:'List linked packages in a conda environment.'
        remove:'Remove a list of packages from a specified conda environment.'
        uninstall:'Alias for conda remove'
    )
    help=(
        help:'Displays a list of available conda commands and their help strings.'
    )
    config=(
        config:'Modify configuration values in .condarc.'
    )
    special=(
        run:'Launches an application installed with Conda.'
        init:'Initialize conda into a regular environment. (DEPRECATED)'
        package:'Low-level conda package utility. (EXPERIMENTAL)'
        bundle:'Create or extract a "bundle package" (EXPERIMENTAL)'
    )
    external=(
        env:'Manage environments.'
        build:'tool for building conda packages'
        )
    _describe -t package_commands "package commands" package
    _describe -t maint_commands "maint commands" maint
    _describe -t environment_commands "environment commands" environment
    _describe -t help_commands "help commands"  help
    _describe -t config_commands "config commands"  config
    _describe -t special_commands "special commands"  special
    _describe -t external_commands "external commands"  external
}

__conda_caching_policy() {
  local -a oldp
  oldp=( "$1"(Nmh+12) ) # 12 hour
  (( $#oldp ))
}

local -a opts help_opts json_opts env_opts channel_opts install_opts

opts=(
    '(-h --help)'{-h,--help}'[show this help message and exit]'
    '(-V --version)'{-V,--version}'[show program''s version number and exit]'
)

help_opts=(
    '(-h --help)'{-h,--help}'[show this help message and exit]' \
    )

json_opts=(
    '--json[report all output as json.]' \
    )

env_opts=(
    '(-n --name -p --prefix)'{-n,--name}'[name of environment]:environment:__conda_envs' \
    '(-n --name -p --prefix)'{-p,--prefix}'[full path to environment prefix]:path:_path_files' \
    )

channel_opts=(
    '(-c --channel)'{-c,--channel}'[additional channel to search for packages]:channel:__conda_channels'\
    '--override-channels [do not search default or .condarc channels]' \
    '--use-index-cache[use cache of channel index files]' \
    '--use-local[use locally built packages]' \
    )

install_opts=(
    '(-y --yes)'{-y,--yes}'[do not ask for confirmation]' \
    '--dry-run[only display what would have been done]' \
    '(-f --force)'{-f,--force}'[force install]' \
    '--file[read package versions from file]:file:_path_files' \
    '--no-deps[do not install dependencies]' \
    '(-m --mkdir)'{-m,--mkdir}'[create prefix directory if necessary]' \
    '--offline[offline mode, don''t connect to internet]' \
    '--no-pin[ignore pinned file]' \
    '(-q --quiet)'{-q,--quiet}'[do not display progress bar]'\
    '--copy[Install all packages using copies instead of hard- or soft-linking]' \
    '--alt-hint[Use an alternate algorithm to generate an unsatisfiable hint]' \
    )

_arguments -C $opts \
           ': :->command' \
           '*:: :->subcmd'

# the magic function, complete either a package or a package and it's version
__magic(){
    local -a last_item available_packages current_package
    last_item=$line[$CURRENT]
    available_packages=($( __conda_package_available ))
    if compset -P "*=" ; then
        current_package="$IPREFIX[1,-2]"
        __conda_describe_package_version $current_package
    else
        __describe_conda_package_available
        if [[ -n $last_item ]] && (( ${available_packages[(I)$last_item]} )); then
            compset -P '*'
            __conda_describe_package_specs
        fi
    fi
}

case $state in
(command)
    __conda_commands
    ;;
(subcmd)
    case ${line[1]} in
    (info)
        _arguments -C $help_opts \
                      '--json[report all output as json.]' \
                      '(-a --all)'{-a,--all}'[show all information, (environments, license, and system information]' \
                      '(-e --envs)'{-e,--envs}'[list all known conda environments]' \
                      '(-l --license)'{-l,--license}'[display information about local conda licenses list]' \
                      '(-s --system)'{-s,--system}'[list environment variables]' \
                      '--root[display root environment path]' \
                      '*:packages:__describe_conda_package_available' \
        ;;
    (help)
        _arguments -C $help_opts \
                      '*:commands:__conda_commands' \
        ;;
    (list)
        _arguments -C $help_opts \
                      $env_opts \
                      $json_opts \
                      '(-c --canonical)'{-c,--canonical}'[output canonical names of packages only]' \
                      '(-e --export)'{-e,--export}'[output requirement string only]' \
                      '(-r --revisions)'{-r,--revision}'[list the revision history and exit]' \
                      '--no-pip[Do not include pip-only installed packages]' \
                      '*:regex:' \
        ;;
    (search)
        _arguments -C $help_opts \
                      $env_opts \
                      $json_opts \
                      $channel_opts \
                      '(-c --canonical)'{-c,--canonical}'[output canonical names of packages only]' \
                      '--unknown[use index metadata from the local package cache]' \
                      '(-o --outdated)'{-o,--outdated}'[only display installed but outdated packages]' \
                      '(-v --verbose)'{-v,--verbose}'[Show available packages as blocks of data]' \
                      '--platform[Search the given platform.]' \
                      '--spec[Treat regex argument as a package specification]' \
                      '*:regex:' \
        ;;
    (create)
        _arguments -C $help_opts \
                      $env_opts \
                      $install_opts \
                      $json_opts \
                      $channel_opts \
                      '--unknown[use index metadata from the local package cache]' \
                      '--clone[path to (or name of) existing local environment]' \
                      '--no-default-packages[ignore create_default_packages in condarc file]' \
                      '*:packages:__magic' \
        ;;
    (install)
        _arguments -C $help_opts \
                    $env_opts \
                    $install_opts \
                    $json_opts \
                    $channel_opts \
                    '--revision[revert to the specified revision]:revision' \
                    '*:packages:__magic' \
        ;;
    (update)
        local -a environment options specifier
        options=('-n' '--name' '-p' '--prefix')
        for i in $options ; do
            (( ${line[(I)$i]} )) && specifier=$i
        done
        [[ -n $specifier ]] && environment="$line[${line[(i)$specifier]}+1]"
        _arguments -C $help_opts \
                      $env_opts \
                      $install_opts \
                      $json_opts \
                      $channel_opts \
                      '--unknown[use index metadata from the local package cache]' \
                      '--all[Update all installed packages in the environment]' \
                      '*:packages:{__conda_packages_installed $specifier $environment}' \
        ;;
    (remove|uninstall)
        local -a environment options specifier
        options=('-n' '--name' '-p' '--prefix')
        for i in $options ; do
            (( ${line[(I)$i]} )) && specifier=$i
        done
        [[ -n $specifier ]] && environment="$line[${line[(i)$specifier]}+1]"
        _arguments -C $help_opts \
                      $env_opts \
                      $json_opts \
                      $channel_opts \
                      '(-y --yes)'{-y,--yes}'[do not ask for confirmation]' \
                      '--dry-run[only display what would have been done]' \
                      '(-a --all)'{-a,--all}'[remove all packages, i.e. the entire environment]' \
                      '--features[remove features (instead of packages)]' \
                      '--no-pin[ignore pinned file]' \
                      '(-q --quiet)'{-q,--quiet}'[do not display progress bar]'\
                      '--offline[offline mode, don''t connect to internet]' \
                      '*:packages:{__conda_packages_installed $specifier $environment}' \
        ;;
    (config)
        # this allows completing multiple keys whet --get is given
        local -a last_item get_opts
        last_item=$line[$CURRENT-1]
        if (( ${line[(I)--get]} ))  && (( ${__conda_config_keys[(I)$last_item]} )) ; then
            get_opts=('*:keys:__conda_describe_existing_config_keys')
        else
            get_opts=''
        fi
        _arguments -C $help_opts \
                      $json_opts \
                      '--system[write to the system .condarc file]' \
                      '--file[write to the given file.]:file:_path_files' \
                      '(      --add --set --remove --remove-key)--get[get the configuration value]:key:__conda_describe_existing_config_keys' \
                      '(--get       --set --remove --remove-key)--add[add one configuration value to a list key]:list key:__conda_describe_list_config_keys:value:' \
                      '(--get --add       --remove --remove-key)--set[set a boolean key]:boolean key:__conda_describe_boolean_config_keys:value:__conda_describe_boolean_config_values' \
                      '(--get --add --set          --remove-key)--remove[remove a configuration value from a list key]:list key:__conda_describe_existing_list_config_keys:value:{__conda_describe_existing_config_values '$last_item'}' \
                      '(--get --add --set --remove             )--remove-key[remove a configuration key (and all its values)]:key:__conda_describe_existing_config_keys' \
                      '(-f --force)'{-f,--force}'[write to the config file using the yaml parser]' \
                      $get_opts
        ;;
    (init)
        _arguments -C $help_opts \
        ;;
    (clean)
        _arguments -C $help_opts \
                      $json_opts \
                      '(-y --yes)'{-y,--yes}'[do not ask for confirmation]' \
                      '--dry-run[only display what would have been done]' \
                      '(-i --index-cache)'{-i,--index-cache}'[remove index cache]' \
                      '(-l --lock)'{-l,--lock}'[remove all conda lock files]' \
                      '(-t --tarballs)'{-t,--tarballs}'[remove cached package tarballs]' \
                      '(-p --packages)'{-p,--packages}'[remove unused cached packages]' \
                      '(-s --source-cache)'{-s,--source-cache}'[remove files from the source cache of conda build]' \
        ;;
    (package)
        _arguments -C $help_opts \
                      $env_opts \
                      '(-w --which)'{-w,--which}'[given some path print which conda package the file came from]:path:_path_files' \
                      '(-L --ls-files)'{-L,--ls-files}'[list all files belonging to specified package]' \
                      '(-r --reset)'{-r,--reset}'[remove all untracked files and exit]' \
                      '(-u --untracked)'{-u,--untracked}'[display all untracked files and exit]' \
                      '--pkg-name[package name of the created package]:pkg_name:' \
                      '--pkg-version[package version of the created package]:pkg_version:' \
                      '--pkg-build[package build number of the created package]:pkg_build:' \
        ;;
    (bundle)
        _arguments -C $help_opts \
                      $env_opts \
                      $json_opts \
                      '(-c --create)'{-c,--create}'[create bundle]' \
                      '(-x --extract)'{-x,--extract}'[extact bundle located at path]:path:_path_files' \
                      '--metadump[dump metadata of bundle at path]:path:_path_files' \
                      '(-q --quiet)'{-q,--quiet}'[do not display progress bar]'\
                      '--bundle-name[name of bundle]:NAME:' \
                      '--data-path[path to data to be included in bundle]:path:_path_files' \
                      '--extra-meta[path to json file with additional meta-data no]:path:_path_files' \
                      '--no-env[no environment]' \
        ;;
    (build)
        _arguments -C $help_opts \
                     '(-c --check)'{-c,--check}'[only check (validate) the recipe]' \
                     '--no-binstar-upload[do not ask to upload the package to binstar]' \
                     '--output[output the conda package filename which would have been created and exit]' \
                     '(-s --source)'{-s,--source}'[only obtain the source (but don''t build)]' \
                     '(-t --test)'{-t,--test}'[test package (assumes package is already build)]' \
                     '--no-test[do not test the package]' \
                     '(-b --build-only)'{-b,--build-only}'[only run the build, without any post processing or testing]' \
                     '(-p --post)'{-p,--post}'[run the post-build logic]' \
                     '(-V --version)'{-V,--version}'[show program''s version number and exit]' \
                     '(-q --quiet)'{-q,--quiet}'[do not display progress bar]' \
                     '--python[Set the Python version used by conda build]' \
                     '--perl[Set the Perl version used by conda build]' \
                     '--numpy[Set the NumPy version used by conda build]' \
                     '*:recipe_path:_path_files' \
        ;;
    (env)
        _arguments -C $opts \
                      ': :->command' \
                      '*:: :->subcmd'
        case $state in
        (command)
            local -a env
            env=(
                create:'Create an environment based on an environment file'
                export:'Export a given environment'
                list:'List the Conda environments'
                remove:'Remove an environment'
                update:'Update the current environment based on environment file'
                )
                _describe -t env_commands "help commands"  env
            ;;
        (subcmd)
            case ${line[1]} in
                (create)
                    _arguments -C $help_opts \
                                  $json_opts \
                                  '(-n --name)'{-n,--name}'[name of environment]:environment:__conda_envs' \
                                  '(-f --file)'{-f,--file}'[environment definition]:file:_path_files' \
                                  '(-q --quiet)'{-q,--quiet}'[]' \
                    ;;
                (export)
                    _arguments -C $help_opts \
                                  '(-n --name)'{-n,--name}'[name of environment]:environment:__conda_envs' \
                                  '(-f --file)'{-f,--file}'[]:file:_path_files' \
                    ;;
                (list)
                    _arguments -C $help_opts \
                                  $json_opts \
                    ;;
                (remove)
                    _arguments -C $help_opts \
                                  $json_opts \
                                  $env_opts \
                                  '(-q --quiet)'{-q,--quiet}'[do not display progress bar]'\
                                  '(-y --yes)'{-y,--yes}'[do not ask for confirmation]' \
                                  '--dry-run[only display what would have been done]' \
                    ;;
                (update)
                    _arguments -C $help_opts \
                                  $json_opts \
                                  '(-n --name)'{-n,--name}'[name of environment]:environment:__conda_envs' \
                                  '(-f --file)'{-f,--file}'[environment definition]:file:_path_files' \
                                  '(-q --quiet)'{-q,--quiet}'[]' \
                    ;;
            esac
            ;;
        esac
        ;;
    esac
    ;;
esac

