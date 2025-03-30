document.addEventListener('DOMContentLoaded', function() {
  const darkModeToggle = document.getElementById('dark-mode-toggle');
  const body = document.body;
 
  const userPrefersDark = localStorage.getItem('darkMode') === 'true';
  if (userPrefersDark) {
      body.classList.add('dark-mode');
  }
 
  darkModeToggle.addEventListener('click', function() {
      body.classList.toggle('dark-mode');
 
      localStorage.setItem('darkMode', body.classList.contains('dark-mode'));
  });
 });