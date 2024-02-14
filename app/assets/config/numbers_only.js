function restrictInput(event) {
  const allowedChars = /[0-9]/;
  const inputChar = event.data;

  if (!allowedChars.test(inputChar)) {
    event.target.value = event.target.value.replace(/[^0-9]/g, "");
  }
}
