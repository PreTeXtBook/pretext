/**
 * Paper size detection.
 *
 * Determines paper size (letter vs a4) from localStorage, or falls back
 * to geographic detection via ipapi.co.
 */

export function getPaperSize() {
    let paperSize = localStorage.getItem("papersize");
    if (paperSize) return paperSize;

    // Try to set papersize based on user's geographic region
    try {
        fetch("https://ipapi.co/json/")
            .then((response) => response.json())
            .then((data) => {
                const continent =
                    data && data.continent_code ? data.continent_code : "";
                paperSize =
                    continent === "NA" || continent === "SA"
                        ? "letter"
                        : "a4";
                const radio = document.querySelector(
                    `input[name="papersize"][value="${paperSize}"]`
                );
                if (radio) {
                    radio.checked = true;
                    localStorage.setItem("papersize", paperSize);
                }
                document.body.classList.remove("a4", "letter");
                document.body.classList.add(paperSize);
            })
            .catch((err) => {
                throw err;
            });
    } catch (e) {
        const radio = document.querySelector(
            'input[name="papersize"][value="letter"]'
        );
        if (radio) radio.checked = true;
    }
    return paperSize || "letter";
}
