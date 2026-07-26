import "./styles.css";
import { main } from "../../../output-es/DagreDemo.Main/index.js";

if (import.meta.hot) {
  import.meta.hot.accept(() => {
    const app = document.getElementById("app");
    if (app) app.innerHTML = "";
    main();
  });
}

main();
