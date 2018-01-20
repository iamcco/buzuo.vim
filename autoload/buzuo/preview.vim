"===============================================================================
"File: autoload/buzuo/preview.vim
"Maintainer: iamcco <ooiss@qq.com>
"Github: http://github.com/iamcco <年糕小豆汤>
"Licence: Vim Licence
"Version: 0.0.1
"===============================================================================
scriptencoding utf-8

" config preview window
function! s:preview_config() abort
    setl filetype=markdown
    setl buftype=nofile
    setl bufhidden=delete
    setl noswapfile
    setl noreadonly
    setl modifiable
    setl nobuflisted
    setl nolist
    setl nowrap
    setl nospell
    setl nofoldenable
    setl textwidth=0
    setl winfixwidth
    setl winfixheight
    setl nonumber
    setl norelativenumber
    setl nocursorcolumn
    setl nocursorline
endfunction

" display preview content
function! s:preview_append(lines) abort
    call setline(1, a:lines)
endfunction

" open preview buffer
function! buzuo#preview#open(content) abort
    let l:current_winid = win_getid()
    let l:columns = &columns / 2
    silent! vertical pedit! preview.buzuo.markdown
    wincmd P
    execute 'vert resize ' . l:columns
    call s:preview_config()
    if a:content !=# v:null
        let l:lines = split(a:content, "\n")
        call s:preview_append(l:lines)
    endif
    call win_gotoid(l:current_winid)
endfunction

" close preview buffer
function! buzuo#preview#close() abort
    pclose
endfunction
