$(document).ready(function() {
    $.validator.setDefaults({
	submitHandler: function() {
	//Ajax submit for contact form
        $.ajax({
                type:'POST',
                url: $('form#comments').attr('action'),
                data: $('form#comments').serializeArray(),
                dataType: "html",
                error:function(){
                    $('#fail').show();
                    $('form#comments')[0].reset();
                    e.preventDefault();
                },
                success: function(response) {
                    $(response).appendTo( $( "#all-comments" ) );
				//window.location.reload(true);
                    $('form#comments')[0].reset();
            }});
	}
    });


});