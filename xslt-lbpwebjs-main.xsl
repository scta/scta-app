<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="1.0">
  <xsl:output method="html"/>
  <!-- params -->
  <!-- check global site setting for images -->
  <xsl:param name="show-images">true</xsl:param>
  <xsl:param name="default-ms-image">reims</xsl:param>
  <xsl:variable name="schema-type" select="/tei:TEI/tei:teiHeader[1]/tei:encodingDesc[1]/tei:schemaRef[1]/@n"/>
  <xsl:param name="show-line-breaks"><!-- aka isDiplomatic? -->
    <xsl:choose>
      <xsl:when test="contains($schema-type, 'critical')">false</xsl:when>
      <xsl:otherwise>true</xsl:otherwise>
    </xsl:choose>
  </xsl:param>
  <xsl:param name="isDiplomatic" select="$show-line-breaks"/> <!-- alias of show line breaks -->

  <!-- this param needs to change if, for example, you want the show xml function to display XML for something other than "critical"; Alternatively, this slug could be found somewhere in the TEI document being processed -->
  <xsl:param name="default-msslug" select="/tei:TEI/tei:teiHeader[1]/tei:fileDesc[1]/tei:sourceDesc[1]/tei:listWit[1]/tei:witness[1]/@n"/>
  <xsl:param name="file-path"/>

  <!-- these params provide different language locales inherited from rails app -->
  <xsl:param name="by_phrase">By</xsl:param>
  <xsl:param name="edited_by_phrase">Edited By</xsl:param>



  <!-- variables-->
  <xsl:variable name="itemid">
        <xsl:value-of select="/tei:TEI/tei:text/tei:body/tei:div/@xml:id"/>
    </xsl:variable>

  <!-- root template -->
  <xsl:template match="/">
  <div>
    <!-- title/publication info -->
    <xsl:call-template name="teiHeaderInfo"/>

    <!-- transform body of text -->
  	<xsl:apply-templates/>

    <!-- prepare footnotes -->
    <div class="footnotes">
      <h1>Apparatus Fontium</h1>
      <xsl:call-template name="footnotes"/>
    </div>
    <!-- prepare variants -->
    <div class="variants">
      <h1>Apparatus Criticus</h1>
      <xsl:call-template name="variants"/>
    </div>
    </div>
  </xsl:template>

  <!-- clear teiHeader -->
  <xsl:template match="tei:teiHeader"/>

  <!-- clear starts-on -->
  <xsl:template match="tei:div[@xml:id='starts-on']"/>

  <!-- heading template -->
  <xsl:template match="tei:head">
    <xsl:variable name="number" select="count(ancestor::tei:div)"/>
    <xsl:variable name="id">
            <xsl:value-of select="@xml:id"/>
        </xsl:variable>
    <xsl:variable name="parent-div-id">
            <xsl:value-of select="./parent::tei:div/@xml:id"/>
        </xsl:variable>

    <xsl:element name="h{$number}">
            <xsl:attribute name="id">
                <xsl:value-of select="$id"/>
            </xsl:attribute>
      <xsl:apply-templates/>
      <!-- conditions shows info button only for divs with a header, with an xml:id
      and on headers that are not question titles -->
      <xsl:if test="$parent-div-id and not(./@type='question-title')">
        <span class="small lbp-div-info">
          <a href="#" class="js-show-info" data-pid="{$parent-div-id}">
            <span class="glyphicon glyphicon-info-sign" aria-hidden="true">I</span>
          </a>
        </span>
      </xsl:if>

    </xsl:element>

  </xsl:template>

  <xsl:template match="tei:div">
    <div id="{@xml:id}" class="plaoulparagraph">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="tei:p">
    <xsl:variable name="pn">
            <xsl:number level="any" from="tei:text"/>
        </xsl:variable>
    <xsl:variable name="pid">
            <xsl:value-of select="@xml:id"/>
        </xsl:variable>

    <div class="para_wrap" id="pwrap_{@xml:id}" style="clear: both; float: none;">
      <p id="{@xml:id}" class="plaoulparagraph">
      <span id="pn{$pn}" class="paragraphnumber">
        <xsl:number level="any" from="tei:text"/>
      </span>
      <xsl:apply-templates/>

      </p>
      <!-- <xsl:if test="./@xml:id">
        <nav class="navbar navbar-default paradiv" id="menu_{@xml:id}" style="display: none;">
          <div class="navbar-header navbar-right">
            <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#para-navbar-collapse-{@xml:id}">
              <span class="sr-only">Toggle navigation</span>
              <span class="icon-bar"></span>
              <span class="icon-bar"></span>
              <span class="icon-bar"></span>
            </button>
          </div>
          <div class="collapse navbar-collapse" id="para-navbar-collapse-{@xml:id}">
            <ul class="nav navbar-nav">
              <li class="dropdown">
                <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false">Comments<span class="caret"></span></a>
                <ul class="dropdown-menu" role="menu">
                  <li><a href="#" class='js-view-comments' data-itemid="{$itemid}" data-pid="{@xml:id}">View Comments</a></li>
                  <li><a href="#" class='js-new-comment' data-itemid="{$itemid}" data-pid="{@xml:id}">Leave a Comment</a></li>
                </ul>
              </li>
              <xsl:if test="$show-images = 'true'">
                <li><a href="#" class="js-show-para-image-zoom-window" data-expressionid="{@xml:id}" data-msslug="{$default-ms-image}">Manuscript Images</a></li>
              </xsl:if>
              <li class="dropdown">
                <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false">Paragraph Text Tools<span class="caret"></span></a>
                <ul class="dropdown-menu" role="menu">
                  <li><a href="#" class='js-show-paragraph-variants' data-itemid="{$itemid}" data-pid="{@xml:id}">Variants</a></li>
                  <li><a href="#" class='js-show-paragraph-notes' data-itemid="{$itemid}" data-pid="{@xml:id}">Notes</a></li>
                  <li><a href="#" class='js-show-paragraph-collation' data-itemid="{@xml:id}">Collation</a></li>
                  <li><a href="#" class='js-show-paragraph-comparison' data-itemid="{@xml:id}">Compare</a></li>
                  <li><a href="#" class='js-show-paragraph-xml' data-itemid="{$itemid}" data-pid="{@xml:id}" data-msslug="{$default-msslug}">XML</a></li>
                  <li><a href="#" class='js-show-paragraph-info' data-itemid="{$itemid}" data-pid="{@xml:id}">Paragraph Info</a></li>

                </ul>
              </li>
              <li><a href="#" class='js-show-paragraph-info' data-itemid="{$itemid}" data-pid="{@xml:id}" data-view="howtocite">How To Cite</a></li>
            </ul>
          </div>
        </nav>
      </xsl:if> -->
    </div>
  </xsl:template>

  <!-- name template -->
  <xsl:template match="tei:name">
    <xsl:variable name="ref">
            <xsl:value-of select="./@ref"/>
        </xsl:variable>
    <xsl:variable name="refID">
            <xsl:value-of select="substring-after($ref, '#')"/>
        </xsl:variable>
    <span class="lbp-name" data-name="{$refID}">
            <xsl:apply-templates/>
        </span>
  </xsl:template>

  <!-- title template -->
  <xsl:template match="tei:title">
    <xsl:variable name="ref">
            <xsl:value-of select="./@ref"/>
        </xsl:variable>
    <xsl:variable name="refID">
            <xsl:value-of select="substring-after($ref, '#')"/>
        </xsl:variable>
    <span class="lbp-title" data-title="{$refID}">
            <xsl:apply-templates/>
        </span>
  </xsl:template>

  <!-- quote template -->
  <xsl:template match="tei:quote">
    <xsl:variable name="quoterefid" select="translate(./@ana, '#', '')"/>
    <xsl:variable name="id" select="./@xml:id"/>
    <xsl:variable name="targetRange" select="./@synch"/>
    <xsl:variable name="source" select="tokenize(./@source, '@')[1]"/>
    <!-- conditional here to maintain functionality with old synch method, but handle wordRange as part of id -->
    <xsl:variable name="targetRange">
        <xsl:choose>
            <xsl:when test="tokenize(./@source, '@')[2]">
                <xsl:value-of select="tokenize(./@source, '@')[2]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="./@synch"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    
    <xsl:choose>
      <xsl:when test="($isDiplomatic = 'true') and $id and contains($source, 'http://scta.info/resource/')">
        <!-- added data-target-paragraph attribut here because it is hard for jquery to get id in html dom -->
        <span id="{@xml:id}" class="lbp-quote js-show-info lbp-quote-clickable js-show-reference-paragraph" data-pid="{$id}" data-url="{$source}" data-target-resource="{$id}" data-target-range="{$targetRange}">
          <xsl:text/>
          <xsl:apply-templates/>
          <xsl:text/>
        </span>
      </xsl:when>
      <xsl:when test="($isDiplomatic = 'true') and $id">
        <span id="{@xml:id}" class="lbp-quote js-show-info lbp-quote-clickable" data-pid="{$id}">
          <xsl:text/>
          <xsl:apply-templates/>
          <xsl:text/>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <span id="{@xml:id}" class="lbp-quote" data-quote="{$quoterefid}">
          <xsl:text>"</xsl:text>
          <xsl:apply-templates/>
          <xsl:text>"</xsl:text>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ref template -->
  <xsl:template match="tei:ref">
    <xsl:variable name="refid" select="translate(./@ana, '#', '')"/>
    <xsl:variable name="corresp" select="translate(./@corresp, '#', '')"/>
    <xsl:variable name="id" select="./@xml:id"/>
    <xsl:variable name="target" select="tokenize(./@target, '@')[1]"/>
    <!-- conditional here to maintain functionality with old synch method, but handle wordRange as part of id -->
    <xsl:variable name="targetRange">
        <xsl:choose>
            <xsl:when test="tokenize(./@target, '@')[2]">
                <xsl:value-of select="tokenize(./@target, '@')[2]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="./@synch"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
    
    <xsl:choose>
      <xsl:when test="($isDiplomatic = 'true') and $id and contains($target, 'http://scta.info/resource/')">
        <!-- added data-target-paragraph attribut here because it is hard for jquery to get id in html dom -->
        <span id="{@xml:id}" class="lbp-ref js-show-info lbp-ref-clickable js-show-reference-paragraph" data-pid="{$id}" data-url="{$target}" data-ref="{$refid}" data-corresp="{$corresp}" data-target-resource="{$id}" data-target-range="{$targetRange}">
          <xsl:text/>
          <xsl:apply-templates/>
          <xsl:text/>
        </span>
      </xsl:when>
      <xsl:when test="($isDiplomatic = 'true') and $id">
        <span id="{@xml:id}" class="lbp-ref js-show-info lbp-ref-clickable" data-pid="{$id}" data-ref="{$refid}" data-corresp="{$corresp}">
          <xsl:text/>
          <xsl:apply-templates/>
          <xsl:text/>
        </span>
      </xsl:when>
      <xsl:otherwise>
      <span id="{@xml:id}" class="lbp-ref" data-ref="{$refid}" data-corresp="{$corresp}">
        <xsl:text/>
        <xsl:apply-templates/>
        <xsl:text/>
      </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



  <!-- unclear template -->
  <xsl:template match="tei:unclear">
    <xsl:variable name="text">
            <xsl:value-of select="./text()"/>
        </xsl:variable>
    <span class="lbp-unclear" data-text="{$text}">
            <xsl:apply-templates/>
        </span>
  </xsl:template>
  <!-- add template -->
  <xsl:template match="tei:add">
    <span class="lbp-add">
            <xsl:apply-templates/>
        </span>
  </xsl:template>
  <!-- del template -->
  <xsl:template match="tei:del">
    <span class="lbp-del">
            <xsl:apply-templates/>
        </span>
  </xsl:template>
  <!-- choice/corr template -->
  <xsl:template match="tei:choice/tei:corr">
    <span class="lbp-corr">(<xsl:apply-templates/>)</span>
  </xsl:template>
  <!-- choice/reg template -->
  <xsl:template match="tei:choice/tei:reg">
    <span class="lbp-reg">(<xsl:apply-templates/>)</span>
  </xsl:template>

  <!-- app template -->
  <!-- <xsl:template match="tei:app">
    <xsl:apply-templates/>
  </xsl:template> -->

  <!-- if figure element is present display description -->
  <xsl:template match="tei:figure">
    <xsl:if test="./tei:graphic/@url">
        <img id="{./@id}" src="{./tei:graphic/@url}" width="50%"/>
    </xsl:if>
  </xsl:template>
  <!-- end figure element handle -->

  <!-- clear rdg template -->
  <xsl:template match="tei:rdg"/>

  <!-- clear note desc bib template -->
  <xsl:template match=" tei:note | tei:desc"/>


  <xsl:template match="tei:cb">
    <xsl:variable name="hashms">
            <xsl:value-of select="@ed"/>
        </xsl:variable>
    <xsl:variable name="ms">
            <xsl:value-of select="translate($hashms, '#', '')"/>
        </xsl:variable>
  	<!-- get side from previous pb -->
    <xsl:variable name="folio-and-side">
      <!-- TODO preceding not working in column A cases where pagebreak is preceding sibling -->
      <xsl:choose>
        <xsl:when test="./preceding-sibling::tei:pb[1]">
          <xsl:value-of select="./preceding-sibling::tei:pb[@ed=$hashms][1]/@n"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="./preceding::tei:pb[@ed=$hashms][1]/@n"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- <xsl:variable name="length"><xsl:value-of select="string-length($folio-and-side)-2"/></xsl:variable> -->
    <xsl:variable name="folio">
      <xsl:choose>
        <xsl:when test="not(contains($folio-and-side, '-'))">
          <xsl:value-of select="$folio-and-side"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="substring-before($folio-and-side, '-')"/>
        </xsl:otherwise>
      </xsl:choose>

    </xsl:variable>
    <!-- <xsl:variable name="side_column"><xsl:value-of select="substring($fullcn, $length+1)"/></xsl:variable> -->
    <xsl:variable name="column">
            <xsl:value-of select="./@n"/>
        </xsl:variable>
    <xsl:variable name="side">
            <xsl:value-of select="substring-after($folio-and-side, '-')"/>
        </xsl:variable>
    <xsl:variable name="break-ms-slug" select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:listWit/tei:witness[@xml:id=$ms]/@n"/>
    <xsl:variable name="surfaceid">
      <xsl:value-of select="concat($break-ms-slug, '/', $folio, $side)"/>
    </xsl:variable>
    <xsl:variable name="canvasid">
      <xsl:choose>
        <xsl:when test="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:listWit/tei:witness[@xml:id=$ms]/@xml:base">
          <xsl:variable name="canvasbase" select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:listWit/tei:witness[@xml:id=$ms]/@xml:base"/>
          <xsl:variable name="canvasend" select="./preceding::tei:pb[@ed=$hashms]/@facs"/>
          <xsl:value-of select="concat($canvasbase, $canvasend)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat('http://scta.info/iiif/', 'xxx-', $break-ms-slug, '/canvas/', $ms, $folio, $side)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- get preceding paragraph id -->
    <xsl:variable name="expressionid" select="./preceding::tei:p/@xml:id"/>



    <span class="lbp-folionumber">
      <!-- data-msslug needs to get info directly from final; default will not work -->
      <xsl:choose>
        <xsl:when test="$show-images = 'true'">
          <a href="#" class="js-show-folio-image" data-canvasid="{$canvasid}" data-surfaceid="{$surfaceid}" data-msslug="{$break-ms-slug}" data-expressionid="{$expressionid}">
            <xsl:value-of select="$ms"/>
            <xsl:value-of select="$folio"/>
            <xsl:value-of select="concat($side, $column)"/>
          </a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$ms"/>
          <xsl:value-of select="$folio"/>
          <xsl:value-of select="concat($side, $column)"/>
        </xsl:otherwise>
      </xsl:choose>
    </span>
    <xsl:text> </xsl:text>
  </xsl:template>

  <xsl:template match="tei:pb">
	  <xsl:variable name="hashms">
            <xsl:value-of select="@ed"/>
        </xsl:variable>
    <xsl:if test="not(//tei:cb[@ed=$hashms])">
	    <xsl:variable name="ms">
                <xsl:value-of select="translate($hashms, '#', '')"/>
            </xsl:variable>
	    <xsl:variable name="folio-and-side">
                <xsl:value-of select="@n"/>
            </xsl:variable>
	    <!-- this variable gets length of Ms abbrev and folio number after substracting side -->
	    <!-- <xsl:variable name="length"><xsl:value-of select="string-length($fullcn)-1"/></xsl:variable> -->
	    <!-- this variable separates isolates folio number by skipping msAbbrev and then not including side designation -->
	    <xsl:variable name="folio">
	      <xsl:choose>
	        <xsl:when test="not(contains($folio-and-side, '-'))">
	          <xsl:value-of select="$folio-and-side"/>
	        </xsl:when>
	        <xsl:otherwise>
	          <xsl:value-of select="substring-before($folio-and-side, '-')"/>
	        </xsl:otherwise>
	      </xsl:choose>
	    </xsl:variable>
	    <!-- this desgination gets side by skipping lenghth of msAbbrev and folio number and then getting the first character that occurs -->
	    <xsl:variable name="side">
                <xsl:value-of select="substring-after($folio-and-side, '-')"/>
            </xsl:variable>

	    <!-- this variable gets the msslug associated with ms initial in the teiHeader -->
	    <xsl:variable name="break-ms-slug" select="/tei:TEI/tei:teiHeader[1]/tei:fileDesc[1]/tei:sourceDesc[1]/tei:listWit[1]/tei:witness[@xml:id=$ms]/@n"/>
	    <!-- get preceding paragraph id -->
	    <xsl:variable name="expressionid" select="./preceding::tei:p/@xml:id"/>

      <xsl:variable name="surfaceid">
        <xsl:value-of select="concat($break-ms-slug, '/', $folio, $side)"/>
      </xsl:variable>



	    <span class="lbp-folionumber">
	      <!-- data-msslug needs to get info directly from final; default will not work -->
	      <xsl:choose>
	        <xsl:when test="$show-images = 'true'">
            <a href="#" class="js-show-folio-image" data-surfaceid="{$surfaceid}" data-msslug="{$break-ms-slug}" data-expressionid="{$expressionid}">
	          <xsl:value-of select="$ms"/>
	          <xsl:value-of select="$folio"/>
	          <xsl:value-of select="$side"/>
	          </a>
	          </xsl:when>
	        <xsl:otherwise>
	          <xsl:value-of select="$ms"/>
	          <xsl:value-of select="$folio"/>
	          <xsl:value-of select="$side"/>
	        </xsl:otherwise>
	      </xsl:choose>
	    </span>
            <xsl:text> </xsl:text>
  	</xsl:if>
  </xsl:template>

  <!-- line numbers -->
  <xsl:template match="tei:body//tei:lb[not(parent::tei:reg)]">
    <!-- first check global setting to see if line breaks should be shown -->
    <xsl:if test="$show-line-breaks = 'true'">
      <xsl:variable name="pbNumber">
        <xsl:choose>
            <xsl:when test="contains(./@type, 'fixed')">
                <xsl:value-of select="tokenize(./@type, '=')[2]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="./preceding::tei:pb[1]/@n"/>   
            </xsl:otherwise>
      </xsl:choose>
      </xsl:variable>
      <xsl:variable name="break" select="./@break"/>
      <xsl:variable name="lineNumber">
        <xsl:choose>
          <xsl:when test="./@n">
            <xsl:value-of select="./@n"/>
          </xsl:when>
          <xsl:when test="not(./preceding::tei:pb[1][ancestor::tei:body])">
            <xsl:variable name="followingPageBreak" select="count(./preceding::tei:pb[1]//following::tei:lb[not(parent::tei:reg)])"/>
            <!--<xsl:message><xsl:value-of select="$followingPageBreak"/></xsl:message>-->
            <xsl:variable name="followingLineBreak" select="count(.//following::tei:lb[not(parent::tei:reg)])"/>
            <!--<xsl:message><xsl:value-of select="$followingLineBreak"/></xsl:message>-->
            <!--<xsl:variable name="lineNumber" select="$followingPageBreak - $followingLineBreak"/>-->
            <!--<xsl:message><xsl:value-of select="$lineNumber"/></xsl:message>-->
            <xsl:variable name="lineCount" select="$followingPageBreak - $followingLineBreak"/>
            <xsl:variable name="startline">
                            <xsl:value-of select="//tei:body//following::tei:lb[1]/@n"/>
                        </xsl:variable>
            <xsl:value-of select="$lineCount + $startline - 1"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="followingPageBreak" select="count(./preceding::tei:pb[1]//following::tei:lb[not(parent::tei:reg)])"/>
            <!--<xsl:message><xsl:value-of select="$followingPageBreak"/></xsl:message>-->
            <xsl:variable name="followingLineBreak" select="count(.//following::tei:lb[not(parent::tei:reg)])"/>
            <!--<xsl:message><xsl:value-of select="$followingLineBreak"/></xsl:message>-->
            <!--<xsl:variable name="lineNumber" select="$followingPageBreak - $followingLineBreak"/>-->
            <!--<xsl:message><xsl:value-of select="$lineNumber"/></xsl:message>-->
            <xsl:value-of select="$followingPageBreak - $followingLineBreak"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="folio">
        <xsl:choose>
          <xsl:when test="not(contains($pbNumber, '-'))">
            <xsl:value-of select="$pbNumber"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="substring-before($pbNumber, '-')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <!-- this desgination gets side by skipping lenghth of msAbbrev and folio number and then getting the first character that occurs -->
      <xsl:variable name="side">
                <xsl:value-of select="substring-after($pbNumber, '-')"/>
            </xsl:variable>
      <xsl:variable name="surfaceid">
        <xsl:value-of select="concat($default-msslug, '/', $folio, $side)"/>
      </xsl:variable>
      <br/> <span class="lbp-line-number" data-break="{$break}" data-ln="{$lineNumber}" data-pb="{$pbNumber}" data-codex="{$default-msslug}" data-surfaceid="{$surfaceid}">
                <xsl:value-of select="$lineNumber"/> </span>
    </xsl:if>
  </xsl:template>
  <!-- END line number creation -->





  <xsl:template match="tei:supplied">
    <span class="lbp-supplied">[<xsl:apply-templates/>]</span>
  </xsl:template>
  <xsl:template match="tei:mentioned">
    <span class="mentioned">'<xsl:apply-templates/>'</span>
  </xsl:template>

  <!-- notes template -->
  <xsl:template match="tei:cit">
    <xsl:apply-templates select="tei:quote|tei:ref"/>
    <xsl:if test="./tei:quote/@source| ./tei:ref/@target|./tei:bibl">
      <xsl:variable name="id">
        <xsl:number count="//tei:cit" level="any" format="a"/>
            </xsl:variable>
        <xsl:text> </xsl:text>
        <sup>
          <a href="#lbp-footnote{$id}" id="lbp-footnotereference{$id}" name="lbp-footnotereference{$id}" class="footnote">
          [<xsl:value-of select="$id"/>]</a>
          <span class="note-display hidden" data-target-id="{./child::*[1]/@xml:id}"/>
        </sup>
      <xsl:text> </xsl:text>
    </xsl:if>

  </xsl:template>
  <xsl:template match="tei:bibl">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- app template -->
  <xsl:template match="tei:app">
    <xsl:variable name="id">
            <xsl:number count="//tei:app" level="any" format="1"/>
        </xsl:variable>
    <span id="lbp-app-lem-{$id}" class="lemma">
            <xsl:apply-templates select="tei:lem"/>
    <xsl:text> </xsl:text>
    <sup>
      <a href="#lbp-variant{$id}" id="lbp-variantreference{$id}" name="lbp-variantreference{$id}" class="appnote">*<!--[<xsl:value-of select="$id"/>]--></a>
      <span class="note-display hidden" data-target-id="lbp-app-lem-{$id}"/>
    </sup>
    </span>
    <xsl:text> </xsl:text>
  </xsl:template>

  <!-- clear apparatus editorial notes -->
  <xsl:template match="tei:app/tei:note"/>

	<!-- clear citation notes -->
	<xsl:template match="tei:cit/tei:note"/>

  <!-- named templates -->

  <!-- header info -->
  <xsl:template name="teiHeaderInfo">
    <div id="lbp-pub-info">
      <h2>
                <span id="sectionTitle" class="sectionTitle">
                    <xsl:value-of select="//tei:titleStmt/tei:title"/>
                </span>
            </h2>
      <h4>
                <xsl:value-of select="$by_phrase"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="//tei:titleStmt/tei:author"/>
            </h4>
      <div>
      <xsl:if test="//tei:titleStmt/tei:editor/text() or //tei:titleStmt/tei:editor/@ref">
        <p>
                        <xsl:value-of select="$edited_by_phrase"/>
                        <xsl:text> </xsl:text>
          <xsl:for-each select="//tei:titleStmt/tei:editor">
            <xsl:choose>
              <xsl:when test="position() = last()">
                <span>
                                        <xsl:value-of select="."/>
                                    </span>
                                    <xsl:text/>
              </xsl:when>
              <xsl:otherwise>
                <span>
                                        <xsl:value-of select="."/>
                                    </span>
                                    <xsl:text>, </xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </p>
      </xsl:if>
      <xsl:if test="//tei:titleStmt//tei:respStmt">
        <div id="lbp-contributors">
          <p>Contributors:</p>
          <p style="padding-left: 10px">
            <xsl:for-each select="//tei:titleStmt/tei:respStmt">
              <xsl:choose>
                <xsl:when test="./tei:resp/@when">
                  - <span>
                                            <xsl:value-of select="./tei:name"/>
                                        </span>,
                  <span>
                                            <xsl:value-of select="normalize-space(./tei:resp)"/>
                                        </span>,
                  <span>
                                            <xsl:value-of select="./tei:resp/@when"/>
                                        </span>
                  <xsl:text> </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  - <span>
                                            <xsl:value-of select="./tei:name"/>
                                        </span>,
                  <span>
                                            <xsl:value-of select="normalize-space(./tei:resp)"/>
                                        </span>
                  <xsl:text> </xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </p>
        </div>
      </xsl:if>
      <p>Edition: <span id="editionNumber">
                        <xsl:value-of select="//tei:teiHeader/tei:fileDesc/tei:editionStmt/tei:edition/@n"/>
                    </span> | <xsl:value-of select="//tei:teiHeader/tei:fileDesc/tei:editionStmt/tei:edition/tei:date"/>
                </p>
      <p>Authority:
        <xsl:choose>
          <xsl:when test="//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:authority/tei:ref">
            <xsl:value-of select="//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:authority"/>: <a href="{//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:authority/tei:ref/@target}">
                                <xsl:value-of select="//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:authority/tei:ref/@target"/>
                            </a>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:authority"/>
          </xsl:otherwise>
        </xsl:choose>
      </p>
      <div id="lbp-review-display" data-file-url="{$file-path}"/>
      <p>License Availablity: <xsl:value-of select="//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/@status"/>, <xsl:value-of select="//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:p"/> </p>
      <p style="display: none;">
                    <span id="filestem">
                        <xsl:value-of select="//tei:body/tei:div/@xml:id"/>
                    </span>
                </p>
      <xsl:if test="//tei:sourceDesc/tei:listBibl or //tei:sourceDesc/tei:listWit">
        <div id="sources">
          Sources:
          <xsl:for-each select="//tei:sourceDesc/tei:listWit/tei:witness[@n|text()]">
            <a style="padding-left: 10px" href="/#/text?resourceid=http://scta.info/resource/{./@n}">
                                <xsl:value-of select="./@xml:id"/>: <xsl:value-of select="."/>
                            </a>
          </xsl:for-each>
          <xsl:for-each select="//tei:sourceDesc/tei:listBibl/tei:bibl">
            <a style="padding-left: 10px" href="/#/text?resourceid=http://scta.info/resource/{./@n}">
                                <xsl:value-of select="./@xml:id"/>: <xsl:value-of select="."/>
                            </a>
          </xsl:for-each>
        </div>
      </xsl:if>
      </div>

    </div>
  </xsl:template>
  <xsl:template match="tei:div[@xml:id='include-list']">
  </xsl:template>
  <xsl:template match="tei:div[@xml:id='includeList']">
  </xsl:template>

  <xsl:template name="footnotes">
    <ul>
      <!-- checks for cit to create footnote -->
      <xsl:for-each select="//tei:cit">
        <!-- checks checks to see if either quote has source, ref has target or bibl child is present; if not, no display entry is created-->
        <xsl:if test="./tei:quote/@source| ./tei:ref/@target|./tei:bibl">
        <xsl:variable name="id">
                        <xsl:number count="//tei:cit" level="any" format="a"/>
                    </xsl:variable>
        <xsl:variable name="elementid" select="./tei:quote/@xml:id | ./tei:ref/@xml:id"/>
        <li id="lbp-footnote{$id}">

          <a href="#" class="js-show-info" data-pid="{$elementid}">
            <xsl:copy-of select="$id"/>
          </a>

          --
          <xsl:choose>
            <xsl:when test="./tei:quote">
              <xsl:call-template name="quote-bibl"/>
            </xsl:when>
            <xsl:when test="./tei:ref">
              <xsl:call-template name="ref-bibl"/>
            </xsl:when>
          </xsl:choose>
        </li>
        </xsl:if>
      </xsl:for-each>
    </ul>
  </xsl:template>
  <xsl:template name="quote-bibl">
    <xsl:variable name="source" select="tokenize(./tei:quote[1]/@source, '@')[1]"/>
    
    <!-- conditional here to maintain functionality with old synch method, but handle wordRange as part of id -->
    <xsl:variable name="targetRange">
        <xsl:choose>
            <xsl:when test="tokenize(./tei:quote[1]/@source, '@')[2]">
                <xsl:value-of select="tokenize(./tei:quote[1]/@source, '@')[2]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="./tei:quote[1]/@synch"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    

    <xsl:choose>
      <xsl:when test="contains($source, 'http://scta.info/resource/')">
        <!-- added data-target-paragraph attribut here because it is hard for jquery to get id in html dom -->
        <a href="{$source}" data-url="{$source}" class="js-show-reference-paragraph" data-target-resource="{./tei:quote[1]/@xml:id}" data-target-range="{$targetRange}">
          <xsl:choose>
            <xsl:when test="./tei:bibl">
              <xsl:apply-templates select="./tei:bibl"/>
            </xsl:when>
            <xsl:otherwise>
              <!--<xsl:value-of select="$source"/>-->
              Vide
            </xsl:otherwise>
          </xsl:choose>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="./tei:bibl"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="ref-bibl">
    <xsl:variable name="target" select="tokenize(./tei:ref[1]/@target, '@')[1]"/>
    <!-- conditional here to maintain functionality with old synch method, but handle wordRange as part of id -->
    <xsl:variable name="targetRange">
        <xsl:choose>
            <xsl:when test="tokenize(./tei:ref[1]/@target, '@')[2]">
                <xsl:value-of select="tokenize(./tei:ref[1]/@target, '@')[2]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="./tei:ref[1]/@synch"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="contains($target, 'http://scta.info/resource/')">
        <!-- added data-target-paragraph attribute here because it is hard for jquery to get id in html dom -->
        <a href="{$target}" data-url="{$target}" class="js-show-reference-paragraph" data-target-resource="{./tei:ref[1]/@xml:id}" data-target-range="{$targetRange}">
          <xsl:choose>
            <xsl:when test="./tei:bibl">
              <xsl:apply-templates select="./tei:bibl"/>
            </xsl:when>
            <xsl:otherwise>
              <!--<xsl:value-of select="$target"/>-->
              Vide
            </xsl:otherwise>
          </xsl:choose>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="./tei:bibl"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



  <xsl:template name="variants">
    <ul class="variantlist">
      <xsl:for-each select="//tei:app">
        <xsl:variable name="id">
          <xsl:number count="//tei:app" level="any" format="1"/>
        </xsl:variable>

        <li id="lbp-variant{$id}">
          <a>
            <xsl:copy-of select="$id"/>
          </a>
          <text> -- </text>

          <xsl:value-of select="tei:lem"/>
            <xsl:text> ] </xsl:text>
          <xsl:for-each select="tei:rdg">
            <xsl:choose>
              <xsl:when test="./@type='variation-absent'">
                <xsl:value-of select="."/>
                                <xsl:text> </xsl:text>
                <em>om.</em>
                                <xsl:text> </xsl:text>
                <!--<xsl:value-of select="translate(@wit, '#', '')"/><xsl:text>   </xsl:text>-->
                <xsl:call-template name="sigla"/>
              </xsl:when>
            	<xsl:when test="./@type='variation-present'">
            		<xsl:choose>
            			<xsl:when test="./@cause='repetition'">
            				<xsl:text> </xsl:text>
            				<em>iter</em>
            				<!--<xsl:value-of select="translate(@wit, '#', '')"/><xsl:text> </xsl:text>-->
            			  <xsl:call-template name="sigla"/>
            			</xsl:when>
            			<xsl:otherwise>
            				<xsl:text> </xsl:text>
            				<xsl:value-of select="."/>
                                        <xsl:text> </xsl:text>
            				<em>in textu</em>
                                        <xsl:text> </xsl:text>
            				<!--<xsl:value-of select="translate(@wit, '#', '')"/><xsl:text> </xsl:text>-->
            			  <xsl:call-template name="sigla"/>
            			</xsl:otherwise>
            		</xsl:choose>
            	</xsl:when>

            	<xsl:when test="./@type='correction-addition'">
            		<xsl:value-of select="tei:add"/>
                                <xsl:text> </xsl:text>
            		<em>add.</em>
                                <xsl:text> </xsl:text>
            		<!--<xsl:value-of select="translate(@wit, '#', '')"/><xsl:text>   </xsl:text>-->
            	  <xsl:call-template name="sigla"/>
            	</xsl:when>

            	<xsl:when test="./@type='correction-deletion'">
            		<xsl:value-of select="tei:del"/>
                                <xsl:text> </xsl:text>
            		<em>add. sed del.</em>
                                <xsl:text> </xsl:text>
            		<!--<xsl:value-of select="translate(@wit, '#', '')"/><xsl:text>   </xsl:text>-->
            	  <xsl:call-template name="sigla"/>
            	</xsl:when>
              <xsl:when test="./@type='correction-substitution'">
            		<xsl:value-of select="tei:subst/tei:add"/>
                                <xsl:text> </xsl:text>
            		<em>corr. ex</em>
                                <xsl:text> </xsl:text>
            		<xsl:value-of select="tei:subst/tei:del"/>
                                <xsl:text> </xsl:text>
            		<!--<xsl:value-of select="translate(@wit, '#', '')"/><xsl:text>   </xsl:text>-->
                <xsl:call-template name="sigla"/>
            	</xsl:when>
            	<xsl:otherwise>
                <xsl:value-of select="."/>
                                <xsl:text> </xsl:text>
            	  <!--<xsl:choose>
            	    <xsl:when test="./@facs">
                 	  <xsl:variable name="ms" select="translate(./@wit, '#', '')"/>
                 	  <xsl:variable name="msSlug" select="/tei:TEI/tei:teiHeader[1]/tei:fileDesc[1]/tei:sourceDesc[1]/tei:listWit[1]/tei:witness[@xml:id=$ms]/@n"/>
                 	  <xsl:variable name="line" select="substring-after(./@facs, '/')"/>
                 	  <xsl:variable name="surface" select="substring-before(./@facs, '/')"/>
                   <span class="show-line-witness" data-ln="{$line}" data-pb="{$surface}" data-codex="{$msSlug}" data-surfaceid="{concat($msSlug, '/', $surface)}">
                     <xsl:value-of select="translate(@wit, '#', '')"/><xsl:text>   </xsl:text>
                   </span>
              	  </xsl:when>
            	    <xsl:otherwise>
            	      <xsl:value-of select="translate(@wit, '#', '')"/><xsl:text>   </xsl:text>
            	    </xsl:otherwise>
            	  </xsl:choose>-->
            	  <xsl:call-template name="sigla"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </li>
      </xsl:for-each>
    </ul>
  </xsl:template>
  <xsl:template name="sigla">
    <xsl:choose>
      <xsl:when test="./@facs">
        <xsl:variable name="ms" select="translate(./@wit, '#', '')"/>
        <xsl:variable name="msSlug" select="/tei:TEI/tei:teiHeader[1]/tei:fileDesc[1]/tei:sourceDesc[1]/tei:listWit[1]/tei:witness[@xml:id=$ms]/@n"/>
        <xsl:variable name="line" select="substring-after(./@facs, '/')"/>
        <xsl:variable name="surface" select="substring-before(./@facs, '/')"/>
        <span class="show-line-witness" data-ln="{$line}" data-pb="{$surface}" data-codex="{$msSlug}" data-surfaceid="{concat($msSlug, '/', $surface)}">
          <xsl:value-of select="translate(@wit, '#', '')"/>
                    <xsl:text>   </xsl:text>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="translate(@wit, '#', '')"/>
                <xsl:text>   </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>