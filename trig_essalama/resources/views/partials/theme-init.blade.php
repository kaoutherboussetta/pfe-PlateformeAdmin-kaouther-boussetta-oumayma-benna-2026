{{-- Thème unique : sombre. L'option clair est désactivée. --}}
<script>
(function () {
    try {
        localStorage.removeItem('trig-theme');
    } catch (e) {}
    document.documentElement.setAttribute('data-theme', 'dark');
})();
</script>
