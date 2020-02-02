(function($) {
    $(function() {
        removeLastSemicolon();
    });
    function removeLastSemicolon() {
        var removedSemicolon = $('.cgiar-subjects').text().trim().replace(/\;$/, '');
        $('.cgiar-subjects').text(removedSemicolon);
    }
})(jQuery);