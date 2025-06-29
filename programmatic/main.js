// Complete basket functionality implementation - FIXED

// Global variables for data storage
let BASKET = [];
let PRODUCTS = [];
let COMPANY = {};
let SITE = {};

// Device detection
const IS_M = window.innerWidth < 777;
const IS_MOBILE =
  /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
    navigator.userAgent
  );

// Helper functions for DOM manipulation
function img(src, alt) {
  const element = document.createElement("img");
  element.src = src;
  element.alt = element.title = alt;
  return element;
}

function em(text) {
  const element = document.createElement("em");
  element.textContent = text;
  return element;
}

function p(text) {
  const element = document.createElement("p");
  element.textContent = text;
  return element;
}

function p2(html) {
  const element = document.createElement("p");
  element.innerHTML = html;
  return element;
}

function btn(text) {
  const element = document.createElement("button");
  element.textContent = text;
  return element;
}

function li(text = "") {
  const element = document.createElement("li");
  if (text) element.textContent = text;
  return element;
}

function rmAfter(element) {
  if (!element) return;
  let sibling = element.nextSibling;
  const toRemove = [];
  while (sibling) {
    toRemove.push(sibling);
    sibling = sibling.nextSibling;
  }
  toRemove.forEach((el) => el.remove());
}

function insertAfter(referenceNode, newNode) {
  referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
}

// Helper functions for DOM manipulation (add these after existing helper functions)
function lnkimg(href, src, alt) {
  const link = document.createElement("a");
  link.href = href;
  const img = document.createElement("img");
  img.src = src;
  img.alt = img.title = alt;
  link.appendChild(img);
  return link;
}

function lnk(href, text) {
  const link = document.createElement("a");
  link.href = href;
  link.textContent = text;
  return link;
}

function br() {
  return document.createElement("br");
}

function div() {
  return document.createElement("div");
}

function getLogo() {
  const logo = document.createElement("div");
  logo.className = "logo";
  const img = document.createElement("img");
  img.src = "/logo.jpg";
  img.alt = COMPANY.slogan || "";
  img.title = COMPANY.slogan || "";
  img.className = "logo";
  logo.appendChild(img);
  return logo;
}

function imgWithBtn(src, btnText, btnLink, slogans) {
  const container = document.createElement("div");
  container.className = "bigImg";

  const img = document.createElement("img");
  img.src = src;
  img.alt = COMPANY.slogan || "";

  const overlay = document.createElement("div");

  if (slogans && slogans.length >= 2) {
    const em1 = document.createElement("em");
    em1.textContent = slogans[0];
    const em2 = document.createElement("em");
    em2.textContent = slogans[1];
    overlay.appendChild(em1);
    overlay.appendChild(em2);
  }

  const button = document.createElement("button");
  button.textContent = btnText;
  button.onclick = () => {
    window.location.href = btnLink + window.location.search;
  };
  overlay.appendChild(button);

  container.appendChild(img);
  container.appendChild(overlay);

  return container;
}

// Load data function
async function loadData() {
  try {
    const [companyResponse, productsResponse, siteResponse] = await Promise.all(
      [
        fetch("/data/company.json"),
        fetch("/data/products.json"),
        fetch("/data/site.json"),
      ]
    );

    COMPANY = await companyResponse.json();
    const productsData = await productsResponse.json();
    PRODUCTS = productsData.products || [];
    SITE = await siteResponse.json();
  } catch (error) {
    console.error("Error loading data:", error);
  }
}

// Basket functionality - YOUR EXACT IMPLEMENTATION
function changeBtnAddToBasket(parent, display) {
  const btn = parent.querySelector(".btnAddToBasket");
  if (btn) {
    btn.style.display = display;
    rmAfter(btn);
  }
  return btn;
}

function basketAdder(prevElem, prdId) {
  const exi = BASKET.find((p) => p.id == prdId);
  const $q = em(exi.quantity + " " + (SITE.quantity || "Adet"));
  const mbs = exi.quantity > 1 || true ? "minus" : "delete";
  const mbs2 = exi.quantity > 1 ? "çıkart" : "sil";
  const $mb = img("/static/img/" + mbs + ".png", mbs2);

  $mb.addEventListener("click", () => {
    if (exi.quantity > 1) {
      decreaseBasket(prdId, exi.quantity);
    } else {
      changeBtnAddToBasket($mb.parentElement, "inline-block");
      removeFromBasket(prdId);
    }
  });

  const $pb = img("/static/img/plus.png", "ekle");
  $mb.className = $pb.className = "bskbtn";
  $pb.addEventListener("click", () => {
    addToBasket(prdId);
  });

  insertAfter(prevElem, $pb);
  insertAfter(prevElem, $q);
  insertAfter(prevElem, $mb);
}

function fnAddToBasket() {
  this.style.display = "none";
  const x = p("Sepete Eklendi");
  x.style.marginBottom = "5px";
  insertAfter(this, x);
  const prdId = this.parentElement.dataset.id;
  addToBasket(prdId);
  basketAdder(x, prdId);
}

function addToBasket(prdId, quantity) {
  const db = PRODUCTS.find((p) => p.id == prdId);
  if (quantity == undefined) {
    quantity = 1;
  }
  const existing = BASKET.find((p) => p.id == db.id);

  if (existing) {
    BASKET = BASKET.map((p) =>
      p.id === existing.id ? { ...p, quantity: existing.quantity + 1 } : p
    );
  } else {
    BASKET.push({
      id: db.id,
      name: db.name,
      url: db.url,
      price: db.price,
      quantity: quantity,
    });
  }
  refreshBasket();
}

function decreaseBasket(prdId, quantity) {
  BASKET = BASKET.map((p) =>
    p.id === prdId ? { ...p, quantity: quantity - 1 } : p
  );
  refreshBasket();
}

function emptyBasket() {
  BASKET.forEach((p) => {
    cPrd("#products", p.id);
    cPrd(".prd", p.id);
  });
  BASKET = [];
  refreshBasket();
}

function removeFromBasket(prdId) {
  BASKET = BASKET.filter((p) => p.id !== prdId);
  refreshBasket();
  cPrd("#products", prdId);
  cPrd(".prd", prdId);
}

function cPrd(sel, prdId) {
  const p = document.querySelector(sel + " > li[data-id='" + prdId + "']");
  if (p) {
    changeBtnAddToBasket(p, "inline-block");
  }
}

function cPrdAdd(sel, p) {
  const pp = document.querySelector(sel + " > li[data-id='" + p.id + "']");
  if (pp) {
    basketAdder(changeBtnAddToBasket(pp, "none"), p.id);
  }
}

function calcShip(w) {
  if (w <= 3) {
    return 146;
  } else if (w <= 5) {
    return 168;
  } else if (w <= 10) {
    return 192 / 2;
  } else if (w < 15) {
    return 247 / 2;
  } else {
    return 0;
  }
}

function getTotals() {
  let total = 0;
  const qp = [];
  let w = 0;

  BASKET.forEach((p) => {
    qp.push(`${p.id}=${p.quantity}`);
    total += p.quantity * p.price;
    const numPart = Number.parseInt(p.id.replace(/\D/g, ""), 10);
    w += (numPart / 1000) * p.quantity;
  });

  return { total, qp, w };
}

function doProductInner($p, prd, isLinked) {
  const $img = img("", prd.name);
  $img.src = "/static/img/products/" + prd.url + ".jpg";
  $p.append($img);

  const $n = document.createElement("h2");
  $n.textContent = prd.name;
  $img.dataset.url = $n.dataset.url = prd.url;
  $p.append($n);

  const $pr = document.createElement("strong");
  $pr.innerHTML = `${prd.price} TL <em>(KDV Dahil)</em>`;
  $p.append($pr);

  if (isLinked) {
    $img.addEventListener("click", fpc);
    $n.addEventListener("click", fpc);
    $p.append(p(prd.shortDesc || ""));
  }
}

function fpc() {
  window.location.href =
    "/products/" + this.dataset.url + ".html" + window.location.search;
}

function refreshBasket() {
  const { total, qp, w } = getTotals();
  history.replaceState(null, "", `?${qp.join("&")}`);

  const $bi = document.getElementById("basketInfo");
  if (BASKET.length > 0) {
    $bi.querySelector("div").textContent = BASKET.reduce(
      (sum, item) => sum + item.quantity,
      0
    );
    $bi.style.visibility = "visible";
  } else {
    $bi.querySelector("div").textContent = "";
    $bi.style.visibility = "hidden";
  }

  const $ul = document.querySelector("#basket ul");
  $ul.innerHTML = "";
  rmAfter($ul);

  const $be = document.querySelector("#btnEmptyBasket");
  if ($be) {
    $be.style.display = "none";
  }

  if (BASKET.length > 0) {
    let frag = document.createDocumentFragment();
    const $b = document.querySelector("#basket");

    if ($be) {
      $be.style.display = "inline-block";
    }

    const $pTotal = p("");
    $pTotal.id = "pTotal";
    $pTotal.textContent =
      (SITE.productTotal || "Ürün Tutarı") +
      " : " +
      formatPrice(total) +
      " " +
      (SITE.vatIncluded || "(KDV Dahil)");
    frag.append($pTotal);

    const $e = em(
      SITE.freeShippingNote || "15 kg ve üzeri siparişlerde kargo ücretsizdir."
    );
    $e.style.fontSize = "13px";
    $e.style.color = "#333";
    $e.style.paddingBottom = "8px";
    $e.style.display = "block";
    $e.style.marginTop = "-5px";

    const ship = calcShip(w);
    if (w < 15) {
      const $c = p(
        (SITE.shippingCost || "Kargo Ücreti:") +
          " " +
          ship +
          (SITE.shippingTaxNote || " TL (Vergiler Dahil)")
      );
      frag.append($c);
      frag.append($e);
    } else {
      $e.textContent = SITE.shippingFree || "Kargonuz ücretsiz.";
      frag.append($e);
    }

    const $total = p("");
    $total.id = "total";
    $total.textContent =
      (SITE.grandTotal || "Genel Toplam") + " : " + formatPrice(total + ship);
    frag.append($total);

    $bi.querySelector("em").textContent = formatPrice(total);

    const $bw = btn(SITE.orderViaWhatsapp || "Whatsapp'dan Siparişini İlet");
    $bw.id = "btnOrderFromWhatsapp";
    $bw.addEventListener("click", () => {
      const phone = COMPANY.phone.replace(/\D/g, "");
      let message = "Merhaba,\n\n";

      BASKET.forEach((p) => {
        message += `${p.quantity} ${p.name} (${p.price} x ${p.quantity})\n`;
      });

      const { total, qp, w } = getTotals();
      const ship = calcShip(w);

      message +=
        "\n" +
        (SITE.productTotal || "Ürün Tutarı") +
        " : " +
        formatPrice(total);
      message +=
        "\n" + (SITE.shippingCost || "Kargo Ücreti") + " :" + formatPrice(ship);
      message +=
        "\n" +
        (SITE.grandTotal || "Genel Toplam") +
        " :" +
        formatPrice(total + ship);
      message += "\n\nSatın almak istiyorum.";

      const encoded = encodeURIComponent(message);
      if (IS_MOBILE) {
        window.open(`https://wa.me/${phone}?text=${encoded}`, "_blank");
      } else {
        window.open(
          `https://web.whatsapp.com/send?phone=${phone}&text=${encoded}`,
          "_blank"
        );
      }
    });

    frag.append($bw);

    const no_wa_text =
      (SITE.notUsingWhatsapp || "WhatsApp kullanmıyorsanız") +
      ",<br/>" +
      (SITE.contactUsWithEmail || "sipariş ve sorularınız için bize") +
      " <a target='_blank' href='mailto:" +
      COMPANY.email +
      "'>" +
      COMPANY.email +
      "</a> " +
      (SITE.reachUsViaEmail || "adresimizden ulaşabilirsiniz") +
      ".";

    const no_wa = p2(no_wa_text);
    no_wa.id = "no_wa";
    frag.append(no_wa);

    $b.append(frag);

    frag = document.createDocumentFragment();

    BASKET.forEach((p) => {
      const $li = li();
      const $db = img("/static/img/delete.png", "sil");
      $db.className = "btnDelete";
      $db.addEventListener("click", () => {
        removeFromBasket(p.id);
      });

      $li.append($db);
      doProductInner($li, p, true);
      basketAdder($li.lastElementChild, p.id);
      frag.append($li);

      cPrdAdd("#products", p);
      cPrdAdd(".prd", p);
    });

    $ul.append(frag);
  }

  showBasket();
}

function showBasket() {
  const p = document.getElementById("basket");
  const b = document.getElementById("btnShowBasket");
  b.dataset.active = "true";
  b.innerHTML = SITE.hideBasket || "Sepeti Gizle";
  p.style.height = "fit-content";
}

function hideBasket() {
  const p = document.getElementById("basket");
  const b = document.getElementById("btnShowBasket");
  b.dataset.active = "false";
  b.innerHTML = SITE.showBasket || "Sepeti Göster";
  p.style.height = IS_M ? "260px" : "220px";
}

function formatPrice(price) {
  return price.toLocaleString("tr-TR") + " TL";
}

// Global functions for HTML onclick handlers
function toggleMenu(element) {
  const items = element.parentElement.querySelectorAll(".menu-item");
  const isOpen = element.dataset.open === "true";

  if (isOpen) {
    element.dataset.open = "false";
    const img = element.querySelector("img");
    if (img) img.src = "/static/img/menu.png";
    items.forEach((item) => (item.style.display = "none"));
  } else {
    element.dataset.open = "true";
    const img = element.querySelector("img");
    if (img) img.src = "/static/img/close.png";
    items.forEach((item) => (item.style.display = "block"));
  }
}

function navigateTo(element) {
  const url = element.dataset.url;
  if (url) {
    window.location.href = url + window.location.search;
  }
}

function navigateToProduct(element) {
  const url = element.dataset.url;
  if (url) {
    window.location.href =
      "/products/" + url + ".html" + window.location.search;
  }
}

// WhatsApp function
function openWhatsApp(phone) {
  const message = "Merhaba";
  const cleanPhone = phone.replace(/\s/g, "");

  if (IS_MOBILE) {
    window.open(`https://wa.me/${cleanPhone}?text=${message}`, "_blank");
  } else {
    window.open(
      `https://web.whatsapp.com/send?phone=${cleanPhone}&text=${message}`,
      "_blank"
    );
  }
}

// Enhanced footer generation function (matching your JS structure)
function doFooter($body) {
  const $f = document.createElement("footer");

  $f.append(
    imgWithBtn(
      "/static/img/pages/footer.jpg",
      SITE.footSloganBtn,
      SITE.footSloganLnk,
      [SITE.footImgSloganStart, SITE.footImgSloganEnd]
    )
  );

  const $w = lnkimg(
    "tel:" + COMPANY.phone,
    "/static/img/whatsapp.png",
    "whatsapp"
  );

  $w.addEventListener("click", (e) => {
    e.preventDefault();
    const phone = COMPANY.phone.replace(/\D/g, "");
    const message = "Merhaba";

    if (IS_MOBILE) {
      window.open(`https://wa.me/${phone}?text=${message}`, "_blank");
    } else {
      window.open(
        `https://web.whatsapp.com/send?phone=${phone}&text=${message}`,
        "_blank"
      );
    }
  });

  const $social = div();
  $social.className = "social";
  $social.append(
    lnkimg(COMPANY.instagram, "/static/img/instagram.png", "instagram"),
    $w
  );

  $f.append(
    br(),
    br(),
    $social,
    br(),
    br(),
    lnk("mailto:" + COMPANY.email, COMPANY.email),
    p(COMPANY.name + " © " + new Date().getFullYear()),
    br(),
    lnk(
      "/satis-sozlesmesi.html",
      SITE.distanceSalesAlt || "Distance Sales Agreement"
    ),
    lnk("/kvkk.html", SITE.kvkk || "KVKK"),
    lnk("/gizlilik-politikasi.html", SITE.privacyAlt || "Privacy Policy"),
    lnk("/site-haritasi.html", SITE.sitemap || "Site Map"),
    getLogo()
  );

  $body.append($f);
  return $f;
}

// URL parameter handling
function handleUrlParameters() {
  const params = new URLSearchParams(window.location.search);
  for (const [key, value] of params.entries()) {
    const product = PRODUCTS.find((p) => p.id === key);
    if (product) {
      addToBasket(key, Number.parseInt(value));
    }
  }
}

// Initialize basket functionality
function initializeBasket() {
  const basketInfo = document.getElementById("basketInfo");
  if (basketInfo) {
    basketInfo.addEventListener("click", () => {
      window.location.href = "#basket";
      showBasket();
    });
  }

  const btnShowBasket = document.getElementById("btnShowBasket");
  if (btnShowBasket) {
    btnShowBasket.addEventListener("click", () => {
      if (btnShowBasket.dataset.active === "true") {
        hideBasket();
      } else {
        showBasket();
      }
    });
  }

  const btnEmptyBasket = document.getElementById("btnEmptyBasket");
  if (btnEmptyBasket) {
    btnEmptyBasket.addEventListener("click", emptyBasket);
  }

  // Initialize basket display
  hideBasket();
}

// Initialize when DOM is loaded
document.addEventListener("DOMContentLoaded", async () => {
  console.log("Site loaded successfully");

  try {
    // Load data first
    await loadData();

    // Initialize basket functionality
    initializeBasket();

    // Handle URL parameters after a delay
    setTimeout(() => {
      handleUrlParameters();
    }, 987);

    // Initial basket refresh
    refreshBasket();
  } catch (error) {
    console.error("Error initializing site:", error);
  }
});

// Export functions for global access
window.addToBasket = addToBasket;
window.removeFromBasket = removeFromBasket;
window.toggleMenu = toggleMenu;
window.navigateTo = navigateTo;
window.navigateToProduct = navigateToProduct;
window.openWhatsApp = openWhatsApp;
window.fnAddToBasket = fnAddToBasket;
window.emptyBasket = emptyBasket;
window.showBasket = showBasket;
window.hideBasket = hideBasket;
