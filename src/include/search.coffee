# Copyright (c) 2011 github.com/cactus
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

qurl = 'http://aur.archlinux.org/rpc.php?callback=?'

window.onhashchange = () ->
    hash = gethash()
    if !hash or hash.length == 0
        cleardash()
        $('#q').val('')
        return false
    $('#q').val(hash)
    $('#searchform form input').focus()
    $('#ajax-loading').fadeIn()
    handleinput(false)

cleardash = () ->
    $('#results').empty()
    $('#errmsg').empty().hide()
    $('#result-count').empty().text(0)

gethash = () ->
    hash = location.hash.replace(/^#/, '') || null
    return hash

sethash = (hash) ->
    location.hash = hash

handleinput = (stateupdate = true) ->
    cleardash()
    qval = $('#q').val()
    if qval.length < 3
        err_msg = { 
            short_msg: "query too short", 
            long_msg: "must be at least 3 characters" 
        }
        $('#ajax-loading').fadeOut()
        $('#errmsg').append(ich.error_tpl(err_msg)).fadeIn()
        return false
    doajaxy(qval)
    if stateupdate == true
        sethash(qval)

doajaxy = (searchterm) ->
    submit_data = { "type": "search", "arg": searchterm }
    $.getJSON(qurl, submit_data, (data, txtStatus, req) ->
        if !data or data == ""
            err_msg = { short_msg: "No Results" }
            $('#errmsg').append(ich.error_tpl(err_msg)).fadeIn()
        else if data.type == "error"
            err_msg = { short_msg: data.results }
            $('#errmsg').append(ich.error_tpl(err_msg)).fadeIn()
        else
            packages = for index, obj of data.results
                {pkg: obj}
            $('#results').append(ich.packages_tpl({packages: packages}))
            $('#result-count').text(data.results.length)
        $('#ajax-loading').fadeOut()
    )
    return false

ajaxy_firing_pin = (callable, delay) =>
    $('#ajax-loading').fadeIn()
    # only fire callable once every X timeperiod
    clearTimeout(@ajaxy_timeout)
    @ajaxy_timeout = setTimeout(callable, delay)

setup_ajaxy = () ->
    timeout_len = 500
    $('#searchform form').ajaxError((e, xhr, settings, exception) ->
        cleardash()
        $('#ajax-loading').fadeOut()
        err_msg = { 
            short_msg: "Error fetching data", 
            long_msg: exception 
        }
        $('#errmsg').append(ich.error_tpl(err_msg)).fadeIn()
    )

    $('#searchform form input').keyup((eventObj) => 
        # only fire event if content length has changed
        @oldlen or= 0
        newlen = eventObj.target.value.length
        if (newlen != @oldlen) and (eventObj.target.value != gethash())
            @oldlen = newlen
            ajaxy_firing_pin(handleinput, timeout_len)
    )

$(document).ready(->
    $('#searchform form').submit(-> false)
    setup_ajaxy();
    hash = gethash()
    if hash
        $('#q').empty().val(hash)
        $('#ajax-loading').fadeIn()
        handleinput(false)
    $('#searchform form input').focus()
)
