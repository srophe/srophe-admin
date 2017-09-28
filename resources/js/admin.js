$(document).ready(function() {
    $.validator.setDefaults({
	submitHandler: function(e) {
	//Ajax submit for contact form
        $.ajax({
                type:'POST',
                url: $('form#comments').attr('action'),
                data: $('form#comments').serializeArray(),
                dataType: "html",
                error:function(){
                    $('#fail').show();
                    $(response).prependTo("#fail");
                    $('form#comments')[0].reset();
                    e.preventDefault();
                },
                success: function(response) {
                    //$(response).prependTo("#all-comments");
				//window.location.reload(true);
                    $('form#comments')[0].reset();
                    $(response).prependTo("#all-comments");
            }});
	}
    });

    $("form#comments").validate({
		rules: {
                recaptcha_challenge_field: "required",
			name: "required",
			email: {
				required: true,
				email: true
			},
			comments: {
				required: true,
				minlength: 2
			}
		},
		messages: {
			name: "Please enter your name",
			comments: "Please enter a comment",
			email: "Please enter a valid email address",
			recaptcha_challenge_field: "Captcha helps prevent spamming. This field cannot be empty"
		}
    });

    $('a.delete').bind('click',function(event){
        event.preventDefault();
        $.get(this.href,{},function(response){
            window.location.reload(true);
        })
    })

    $('a#show-pending').bind('click',function(event){
        event.preventDefault();
            $('.Approved').hide();
            $('.Pending').show();
    });
    $('a#show-approved').bind('click',function(event){
        event.preventDefault();
            $('.Pending').hide();
            $('.Approved').show();
    });
    $('a#show-all').bind('click',function(event){
        event.preventDefault();
            $('.status').show();
    });

    //Refresh page
    $('#content').on('click', '.refresh', function(){
        location.reload();
    });

    //Run and display NER
    $('#content').on('click', '.ner', function(event){
        var run = $(this).attr('data-param-run');
        var URL = ($(this).attr('data-url') + '&run=' + run);
        event.preventDefault();
        //$('#tab_ner').tab('show');
        $('#ner-results').load(URL);
        //alert(URL)
    });

    //NOTE: do not think this function is being used.
    $('.update').click( function(event) {
        var URL = $(this).attr('href');
        event.preventDefault();
        $.get(URL,function(data){
          //  $('#ner-results').html(data)
            //console.log(URL)
            alert('Record has been updated!')
        });
        //function(data) { $('#ner-results').html(data); }
        $('#ner-results').load(URL);

    });

    //Popup modal with conflicting names, called from reconcile-refs.xql
    $('#rec-review-frame').load(function(){
        $('#rec-review-frame').contents().find('.ref-conflict').addClass("label label-danger");
        $('#rec-review-frame').contents().find('.ref-conflict').click( function(event) {
            var refs = $(this).attr('href');
            var string = $(this).text();
            var element = $(this).attr('data-element-name');
            var recID = $('#rec-review-frame').contents().find('#syriaca-id').text();
            var URL = ('/exist/apps/srophe-forms/services/reconcile-refs.xql?id=' + recID + '&refs=' + encodeURIComponent(refs) + '&string=' + string + '&element=' + element);
            //var URL = encodeURI('/exist/apps/srophe-forms/services/reconcile-refs.xql?id=http://syriaca.org/person/307&refs=http://syriaca.org/place/13 http://syriaca.org/place/2323&string=Kashkar')
            event.preventDefault();
            $('#rec-review-modal').modal('show');
            $('#rec-review-modal .modal-title').text('Reconcile Conflicts');
            $('#rec-review-modal .modal-body').load(URL);
            //Run xquery update on selected ref, return successful message.
            $('#rec-review-modal').on('click', '.ref-update', function(event){
                var ref = $(this).attr('href');
                var updateURL = ('/exist/apps/srophe-forms/services/reconcile-refs.xql?id=' + recID + '&refs=' + encodeURIComponent(refs) + '&string=' + string + '&new-ref=' +ref + '&element=' + element);
                event.preventDefault();
                $('#rec-review-modal .modal-body').load(updateURL);
            });
        });
    });

    $('#rec-review-modal').on('hidden.bs.modal', function () {
        location.reload();
    })
    
    //Upload record
    $('form#upload').on("submit", function(event) {
        var URL = $(this).attr('action');
        event.preventDefault();
        $.get(URL,function(data){
           $('#response').modal('show');
           $('#response-content').html(data);
        });
    });
});