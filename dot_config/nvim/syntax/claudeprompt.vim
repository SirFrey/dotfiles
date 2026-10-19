" Claude Code's Ctrl+G prompt file: the last response is quoted with a "# "
" prefix on every line, so markdown would render each line as an H1.
" Conceal the prefix and highlight the markdown underneath it instead.
if exists('b:current_syntax')
  finish
endif

syn match cpPrefix /^# \?/ contained conceal
syn match cpLine /^#.*$/ contains=cpPrefix,cpBold,cpCode,cpBullet,cpNumber
syn match cpRule /^# ---$/ contains=cpPrefix
syn match cpHeading /^# #\+ .*$/ contains=cpPrefix,cpHeadingMark,cpCode
syn match cpHeadingMark /\%(^# \)\@<=#\+ / contained conceal
syn match cpQuote /^# >.*$/ contains=cpPrefix,cpQuoteMark,cpBold,cpCode,cpBullet,cpNumber
syn match cpQuoteMark /\%(^# \)\@<=> \?/ contained conceal cchar=▎
syn match cpBanner /^# ─── .*$/ contains=cpPrefix
syn match cpBullet /\%(^# \%(> \?\)\?\s*\)\@<=[-*•] / contained
syn match cpNumber /\%(^# \%(> \?\)\?\s*\)\@<=\d\+\. / contained
syn region cpBold matchgroup=cpBoldDelim start=/\*\*/ end=/\*\*/ oneline concealends contained contains=cpCode
syn match cpCode /`[^`]\+`/ contained
syn match cpReplyBanner /^# ─── Write your reply.*$/ contains=cpPrefix

hi def link cpLine Normal
hi def link cpHeading Title
hi def link cpQuote String
hi def link cpBanner Comment
hi def link cpRule Comment
hi def link cpBullet Special
hi def link cpNumber Number
hi def link cpCode Constant
hi def link cpReplyBanner WarningMsg
hi def cpBold gui=bold cterm=bold

let b:current_syntax = 'claudeprompt'
