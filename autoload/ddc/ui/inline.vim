function! ddc#ui#inline#visible() abort
  return s:->get('inline_popup_id', -1) > 0
endfunction

function! ddc#ui#inline#_show(pos, items, highlight) abort
  if '*nvim_buf_set_extmark'->exists()
    if 's:ddc_namespace'->exists()
      call nvim_buf_clear_namespace(0, s:ddc_namespace, 0, -1)
    else
      let s:ddc_namespace = nvim_create_namespace('ddc')
    endif
  endif

  if a:items->empty() || mode() !=# 'i'
    return
  endif

  const complete_str = ddc#util#get_input('')[a:pos :]
  let word = a:items[0].word
  const remaining = word[complete_str->len():]

  if remaining ==# ''
    return
  endif

  if word->stridx(complete_str) == 0 && '.'->col() == '$'->col()
    " Head matched: Follow cursor text
    let word = remaining
    if exists('*nvim_buf_set_extmark')
      const col = '.'->col() - 1
      const options = #{
            \   virt_text: [[word, a:highlight]],
            \   virt_text_pos: 'overlay',
            \   hl_mode: 'combine',
            \   priority: 0,
            \   right_gravity: v:false,
            \ }
    else
      const col = '.'->col()
    endif
  else
    if '*nvim_buf_set_extmark'->exists()
      const col = 0
      const options = #{
            \   virt_text: [[word, a:highlight]],
            \   hl_mode: 'combine',
            \   priority: 0,
            \ }
    else
      const col = '$'->col() + 1
    endif
  endif

  if '*nvim_buf_set_extmark'->exists()
    " Others: After cursor text
    call nvim_buf_set_extmark(
          \ 0, s:ddc_namespace, '.'->line() - 1, col, options)
    let s:inline_popup_id = 1
  else
    const winopts = #{
          \   pos: 'topleft',
          \   line: '.'->line(),
          \   col: col,
          \   highlight: a:highlight,
          \ }

    " Use popup instead
    if s:inline_popup_id > 0
      call popup_move(s:inline_popup_id, winopts)
      call popup_settext(s:inline_popup_id, [word])
    else
      let s:inline_popup_id = popup_create([word], winopts)
    endif
  endif
endfunction

function! ddc#ui#inline#_hide() abort
  if !('s:inline_popup_id'->exists())
    return
  endif

  if '*nvim_buf_set_virtual_text'->exists()
    if !('s:ddc_namespace'->exists())
      let s:ddc_namespace = nvim_create_namespace('ddc')
    endif

    call nvim_buf_clear_namespace('%'->bufnr(), s:ddc_namespace, 0, -1)
  elseif s:->get('inline_popup_id', -1) > 0
    call popup_close(s:inline_popup_id)
  endif

  let s:inline_popup_id = -1
endfunction
