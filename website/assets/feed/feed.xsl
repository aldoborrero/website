<?xml version="1.0" encoding="utf-8"?>
{{- /* Shows a feed opened in a browser as a page: what a feed is, how to
       subscribe, and the latest entries. One stylesheet for RSS 2.0 and Atom.
       Built from this file as a Hugo template (_partials/feed-xsl.html), which
       fills in the site's stylesheet; feed readers ignore it. A template
       comment, so it is not published (checks/no-comments.nix). */}}
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:atom="http://www.w3.org/2005/Atom"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  exclude-result-prefixes="atom dc">
  <xsl:output method="html" encoding="utf-8" indent="no" doctype-system="about:legacy-compat"/>

  <xsl:variable name="rss" select="/rss/channel"/>
  <xsl:variable name="atom" select="/atom:feed"/>
  <xsl:variable name="title" select="$rss/title | $atom/atom:title"/>
  <xsl:variable name="self" select="$rss/atom:link[@rel='self']/@href | $atom/atom:link[@rel='self']/@href"/>
  <xsl:variable name="home" select="$rss/link | $atom/atom:link[@rel='alternate']/@href"/>
  <xsl:variable name="lang" select="$rss/language | $atom/@xml:lang"/>

  <xsl:template match="/">
    <html lang="en" data-palette="{{ site.Params.palette }}">
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <meta name="robots" content="noindex"/>
        <title><xsl:value-of select="$title"/> (feed)</title>
        <link rel="stylesheet" href="{{ .css }}"/>
      </head>
      <body>
        <div class="page">
          <header class="site-head">
            <div class="row">
              <a class="brand" href="/">{{ site.Title }}</a>
            </div>
          </header>
          <main id="main" class="feed-page">
            <header class="archive-head row">
              <p class="label">Web feed</p>
              <div>
                <h1><xsl:value-of select="$title"/></h1>
                <p>This is a web feed: the address a feed reader follows to show you new entries from <a href="{$home}">this page</a> as they come out. No account and no email: a reader app checks it for you.</p>
              </div>
            </header>
            <div class="row">
              <div></div>
              <div>
                <section class="feed-how" aria-labelledby="feed-how-h">
                  <h2 id="feed-how-h">Subscribe</h2>
                  <ol>
                    <li>Copy this address:
                      <span class="feed-url">
                        <input id="feed-url" type="text" readonly="readonly" value="{$self}" aria-label="Feed address" onfocus="this.select()"/>
                        <button type="button" class="feed-copy" hidden="hidden">Copy</button>
                      </span>
                    </li>
                    <li>Paste it into your feed reader: NetNewsWire, Feedly, Inoreader, Thunderbird or any other app that reads RSS or Atom.</li>
                  </ol>
                  <p class="feed-other">Every feed on the site is listed on <a href="/">the home page</a> and on each section and tag page.</p>
                </section>
                <h2 class="feed-latest">Latest entries</h2>
                <ol class="entries">
                  <xsl:apply-templates select="$rss/item | $atom/atom:entry"/>
                </ol>
              </div>
            </div>
          </main>
        </div>
        <script>
          (function () {
            var b = document.querySelector(".feed-copy"), i = document.getElementById("feed-url");
            if (!navigator.clipboard) return;
            b.hidden = false;
            b.addEventListener("click", function () {
              navigator.clipboard.writeText(i.value).then(function () { b.textContent = "Copied"; setTimeout(function () { b.textContent = "Copy"; }, 2000); });
            });
          })();
        </script>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="item">
    <li>
      <xsl:if test="dc:language != $lang"><xsl:attribute name="lang"><xsl:value-of select="dc:language"/></xsl:attribute></xsl:if>
      <time><xsl:value-of select="concat(number(substring(pubDate, 6, 2)), substring(pubDate, 8, 9))"/></time>
      <h3><a href="{link}"><xsl:value-of select="title"/></a></h3>
    </li>
  </xsl:template>

  <xsl:template match="atom:entry">
    <li>
      <xsl:if test="@xml:lang != $lang"><xsl:attribute name="lang"><xsl:value-of select="@xml:lang"/></xsl:attribute></xsl:if>
      <time><xsl:value-of select="concat(number(substring(atom:published, 9, 2)), ' ', substring('JanFebMarAprMayJunJulAugSepOctNovDec', substring(atom:published, 6, 2) * 3 - 2, 3), ' ', substring(atom:published, 1, 4))"/></time>
      <h3><a href="{atom:link[@rel='alternate']/@href}"><xsl:value-of select="atom:title"/></a></h3>
    </li>
  </xsl:template>
</xsl:stylesheet>
