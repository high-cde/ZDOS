fetch("/status")
  .then(r => r.json())
  .then(d => {
    document.getElementById("status").innerText = JSON.stringify(d);
  });
