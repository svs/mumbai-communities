function toggleMenu() {
  const menu = document.getElementById("mobile-menu");
  const isExpanded = menu.classList.contains("block");

  if (isExpanded) {
    menu.classList.remove("block");
    menu.classList.add("hidden");
  } else {
    menu.classList.remove("hidden");
    menu.classList.add("block");
  }
}