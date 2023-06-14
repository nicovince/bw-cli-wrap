#!/bin/bash

function bw_create_item()
{
    local item_name
    local username
    local password

    item_name="$1"
    username="$2"
    password="$3"

    echo "Create item '${item_name}'"
    bw get template item | jq ".name=\"${item_name}\" | .notes=null | .login=$(bw get template item.login | jq ".username=\"${username}\" | .password=\"${password}\"")" | bw encode | bw create item > /dev/null
}

function folder_exist()
{
    local folder

    folder="$1"
    if [ "${folder}" = "/" -o "${folder}" = "." ]; then
        echo 1
    else
        bw list folders | jq "[ .[] | select(.name == \"${folder}\")] | length"
    fi
}

function bw_get_folder_id()
{
    local folder

    folder="$1"
    bw list folders | jq -r ".[] | select(.name == \"${folder}\") | .id"
}

function bw_get_item_id()
{
    local item_name

    item_name="$1"
    bw list items | jq -r ".[] | select(.name == \"${item_name}\") | .id"
}

function bw_move_item_to_folder()
{
    local item_name
    local folder
    local folder_id
    local item_id

    item_name="$1"
    folder="$2"
    folder_id="$(bw_get_folder_id "${folder}")"
    item_id="$(bw_get_item_id "${item_name}")"

    echo "Move '${item_name} to '${folder}'"
    bw get item "${item_id}" | jq ".folderId=\"${folder_id}\"" | bw encode | bw edit item "${item_id}" > /dev/null
}

function bw_add_uri_to_item()
{
    local uri
    local item_name
    local item_id

    uri="$1"
    item_name="$2"
    item_id="$(bw_get_item_id "${item_name}")"

    echo "Add URI '${uri}' to '${item_name}'"
    bw get item "${item_id}" | jq ".login.uris+=[$(bw get template item.login.uri | jq ".uri=\"${uri}\"")]" | bw encode | bw edit item "${item_id}" > /dev/null
}

function bw_create_folder()
{
    local folder
    local parent

    folder="$1"
    parent="$(dirname "${folder}")"
    if [ "$(folder_exist "${folder}")" -ge 1 ]; then
        echo "Folder ${folder} exists alread"
        return
    fi
    if [ "$(folder_exist "${parent}")" -eq 0 ]; then
        bw_create_folder "${parent}"
    fi
    echo "Create Folder ${folder}"
    bw get template folder | jq ".name=\"${folder}\"" | bw encode | bw create folder
}

function bw_www_login_item()
{
    local item_name
    local username
    local password
    local uri

    item_name="$1"
    username="$2"
    password="$3"
    uri="$4"

    bw_create_item "${item_name}" "${username}" "${password}"
    bw sync
    bw_move_item_to_folder "${item_name}" "www"
    bw sync
    bw_add_uri_to_item "${uri}" "${item_name}"
    bw sync
}
