(function($){
  
  $(document).ready(function() {
    var newTrTpl = null;
    if ($('.lang-editor').length) {
      newTrTpl = '<tr>'+$('.lang-editor .new_key_tpl').html()+'</tr>';
      $('.lang-editor .new_key_tpl').remove()
    }
    $(':input[name=addTr]').bind('click', function() {
      $('.lang-editor tr.adder-row').before(newTrTpl);
    });
    $(':input[name=removeKey]').live('click', function() {
      $this = $(this);
      key = $this.closest('tr').data('key');
      if (key) $('.lang-editor form').append('<input type="hidden" name="removeKey[]" value="'+key+'" />');
      $this.closest('tr').remove();
    });
    
    var progress = {total: $('.lang-editor tr.tr').length, success: 0, warning: 0};
    $('.lang-editor tr.tr').each(function() {
      $this = $(this);
      if ($this.hasClass('warning')) {
        progress.warning++;
      }
      if ($this.hasClass('success')) {
        progress.success++;
      }
    });
    success_p = Math.round((progress.success/progress.total)*100)
    warning_p = Math.round((progress.warning/progress.total)*100)
    $('.progress .bar-success').css('width', success_p+'%')
    $('.progress .bar-warning').css('width', warning_p+'%')
    
    $(':input[name=save]').bind('click', function() {
      valid = true;
      $('.lang-editor tr').removeClass('error');
      $('.lang-editor td span.error').remove();
      
      $(':input[name^=newKey]').each(function() {
        $this = $(this);
        if ($this.val().match(" ")) {
          valid = false;
          $this.closest('tr').addClass('error');
          $this.closest('td').append('<span class="label label-important error">Key cannot have spaces!</span>');          
        }
        if (!$this.val()) {
          valid = false;
          $this.closest('tr').addClass('error');
          $this.closest('td').append('<span class="label label-important error">Key cannot be empty!</span>');          
        }
      });
      $(':input[name^=newRoot]').each(function() {
        $this = $(this);
        if (!$this.val()) {
          valid = false;
          $this.closest('tr').addClass('error');
          $this.closest('td').append('<span class="label label-important error">root cannot be empty!</span>');          
        }
      });
      $(':input[name^=newTrans]').each(function() {
        $this = $(this);
        if (!$this.val()) {
          root_val = $this.closest('tr').find(':input[name^=newRoot]').val();
          $this.val(root_val);
        }
      });
      
      return valid;
    });
  });
  
})(jQuery);