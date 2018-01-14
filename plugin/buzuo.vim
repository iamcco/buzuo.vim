"===============================================================================
"File: plugin/buzuo.vim
"Maintainer: iamcco <ooiss@qq.com>
"Github: http://github.com/iamcco <年糕小豆汤>
"Licence: Vim Licence
"Version: 0.0.1
"===============================================================================
scriptencoding utf-8

if exists('g:buzuo_debug') && g:buzuo_debug
elseif exists('g:buzuo_loaded') && g:buzuo_loaded
    finish
endif
let g:buzuo_loaded = 1

let s:save_cpoptions = &cpoptions
set cpoptions&vim

if !exists('g:buzuo_database_path')
    let g:buzuo_database_path = '~/.buzuo/buzuo.database'
endif

if !exists('g:buzuo_category_candidate')
    let g:buzuo_category_candidate = ['work', 'study', 'personal']
endif

if !exists('g:buzuo_category_default')
    let g:buzuo_category_default = get(g:buzuo_category_candidate, '0', 'default')
endif

if !exists('g:buzuo_type_candidate')
    let g:buzuo_type_candidate = ['now', 'shortterm', 'longterm']
endif

if !exists('g:buzuo_type_default')
    let g:buzuo_type_default = get(g:buzuo_type_candidate, '0', 'default')
endif

function! s:get_complete_candidate(A, L, P) abort
    if a:A =~# '\v^add(:[^:]*)?$'
        let l:a = split(a:A, ':')[0]
        let l:res = []
        for l:category in g:buzuo_category_candidate
            call add(l:res, l:a . ':' . l:category)
        endfor
        return join(l:res, "\n")
    elseif a:A =~# '\v^add:[^:]*:[^:]*$'
        let l:a = substitute(a:A, '\v^(add:[^:]*):[^:]*$', '\1', 'g')
        let l:res = []
        for l:type in g:buzuo_type_candidate
            call add(l:res, l:a . ':' . l:type)
        endfor
        return join(l:res, "\n")
    endif
    return join([ 'init', 'add', 'list' ], "\n")
endfunction

command! -nargs=* -complete=custom,s:get_complete_candidate Buzuo :call buzuo#start(<q-args>)

let s:save_cpoptions = &cpoptions
set cpoptions&vim
