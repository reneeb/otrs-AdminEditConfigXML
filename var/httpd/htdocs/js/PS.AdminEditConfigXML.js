// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

Core.App.Ready(function () {

    var BaseURL = window.location.href.replace( window.location.search, "" );
    var URL     = Core.Config.Get('Baselink') || BaseURL;

    $('#FileSelect').bind( 'change', function() {
        $('#AdminEditConfigXML-Success').hide();
        $('#AdminEditConfigXML-Error').hide();

        $.ajax({
            type: 'POST',
            url: URL,
            dataType: 'json',
            data : {
                Action: 'AdminEditConfigXML',
                Subaction: 'File',
                File: $(this).val()
            },
            success: function(response) {
                if ( response.Success == 0 ) {
                    $('#AdminEditConfigXML-Error').html( response.Message );
                    $('#AdminEditConfigXML-Error').show();
                    return;
                }

                $('#AdminEditConfigXML-File').val( response.File );
                $('#AdminEditConfigXML-Content').val( response.Content );
            },
            error: function(error) {
                $('#AdminEditConfigXML-Error').html( "Server error" );
                $('#AdminEditConfigXML-Error').show();
            }
        });
    });

    $('button').bind('click', function() {
        $('#AdminEditConfigXML-Success').hide();
        $('#AdminEditConfigXML-Error').hide();

        var reload = $(this).data('reload');

        $.ajax({
            type: 'POST',
            url: URL,
            dataType: 'json',
            data : {
                Action: 'AdminEditConfigXML',
                Subaction: 'Save',
                File: $('#AdminEditConfigXML-File').val(),
                Content: $('#AdminEditConfigXML-Content').val(),
                Reload: reload
            },
            success: function(response) {
                if ( response.Success == 0 ) {
                    $('#AdminEditConfigXML-Error').html( response.Message );
                    $('#AdminEditConfigXML-Error').show();
                    return;
                }

                $('#AdminEditConfigXML-Success').show();
            },
            error: function(error) {
                $('#AdminEditConfigXML-Error').html( "Server error" );
                $('#AdminEditConfigXML-Error').show();
            }
        });
    });
});
