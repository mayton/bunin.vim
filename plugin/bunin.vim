" bunin.vim - easy editing included into one line files from compiled priv.js
"
" Author: Anton Zhevak
" Version: 0.0.1
" Source: https://github.com/mayton/bunin.vim

if exists('g:BuninDisabled') || exists('g:BuninLoaded')
    finish
else
    let g:BuninLoaded = 1
endif

function! s:EditIncludedFile()
    " Get current line content
    let l:string = getline(line('.'))

    " Extract from current line content three parts:
    "  1. text before included file
    "  2. included file for editing
    "  3. text after included file
    let l:parts = matchlist(l:string, '\v(.*content\s*:\s*)"(.*)"(.*)')

    " Break script for wrong strings
    if !len(l:parts)
        echo 'Bunin: Unable parse included file'
        return
    endif

    " Save extracted parts to variables with friendly names
    let [l:head, l:content, l:tail] = l:parts[1: 3]

    " Unescape double quotes and backslashes
    let l:content = substitute(l:content, '\v\\(["\\])', '\1', 'g')

    " Replace '\n' to line breaks
    let l:lines = split(l:content, '\\n')

    " Save initial buffer and line numbers, head and tail texts
    let l:buninData = { 'initLine': line('.'), 'initBuffer': bufnr('%'), 'head': l:head, 'tail': l:tail }

    " Create new buffer and switch to it
    new

    " Make it scratch (temporary)
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile

    " Bind data to buffer variable
    let b:buninData = l:buninData

    " Insert included file content to scratch buffer
    call append(0, l:lines)

    " Move cursor to begin
    normal gg

    " Set filetype for syntax highlighting
    set filetype=javascript

    " Call update line function when we leave scratch buffer
    autocmd BufLeave <buffer> call s:InsertTextBack()
endfunction

function! s:InsertTextBack()
    if !exists('b:buninData') || empty(b:buninData)
        echo 'Bunin: No data for actions'
        return
    elseif !bufexists(b:buninData.initBuffer)
        echo 'Bunin: Initial buffer isn\'t exists'
        return
    endif

    " Get all lines content
    let l:lines = getline(0, '$')

    " Escape double quotes and backslashes in every line
    for l:i in range(len(l:lines))
        let l:lines[l:i] = escape(l:lines[l:i], '"\')
    endfor

    " Join lines with '\n'
    let l:content = join(l:lines, '\n')

    " Concatenate head and tail with new content
    let l:content = join([b:buninData.head, l:content, b:buninData.tail], '"')

    " Save initial line to local variable because we will switch buffers
    let l:initLine = b:buninData.initLine

    " Delete scratch buffer
    execute 'bdelete' bufnr('%')

    " Replace old line content with new
    call setline(l:initLine, l:content)

    echo 'Bunin: Content successfully updated'
endfunction

command! BuninEdit call s:EditIncludedFile()
