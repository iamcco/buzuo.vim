"===============================================================================
"File: autoload/buzuo/edit.vim
"Maintainer: iamcco <ooiss@qq.com>
"Github: http://github.com/iamcco <年糕小豆汤>
"Licence: Vim Licence
"Version: 0.0.1
"===============================================================================
scriptencoding utf-8

" save buffer content to database
function! s:save_content() abort
    let l:content = join(getline(1, '$'), "\n")
    call buzuo#update_item(b:buzuo_id, 'content', l:content)
    if v:shell_error ==# 0
        " save success and set nomodified
        setl nomodified
        echo 'save content success! (ง •̀_•́)ง'
    endif
endfunction

" config the buffer
function! s:config() abort
    setl bufhidden=hide
    setl noswapfile
    setl noreadonly
    setl modifiable
    setl nomodified
    augroup buzuo_edit_save
        autocmd!
        autocmd BufWriteCmd <buffer> call s:save_content()
    augroup END
endfunction

" open edit buffer
function! buzuo#edit#open(id, content) abort
    execute 'edit ' . a:id . '.buzuo.markdown'
    " save id for edit item
    let b:buzuo_id = a:id
    " if content is not null
    if a:content !=# v:null
        let l:lines = split(a:content, "\n")
        call setline(1, l:lines)
    endif
    call s:config()
endfunction
