/*******************************************************************************
 * pretext.js
 *******************************************************************************
 * The main front-end controller for PreTeXt documents.
 *
 * Homepage: pretextbook.org
 * Repository: https://github.com/PreTeXtBook/JS_core
 *
 * Authors: Michael DuBois, David Farmer, Rob Beezer
 *
 *******************************************************************************
 */

/* load MathJax if not already loaded */
/* omitted in version 0.1
if(typeof MathJax == 'undefined' ) {
    (function(d, script) {
       script = d.createElement('script');
       script.type = 'text/javascript';
       script.async = true;
       script.onload = function() {
        // remote script has loaded
       };
       script.onerror = function(){
        // something went wrong
       }
       script.src = 'https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS-MML_HTMLorMML-full';
       d.getElementsByTagName('head')[0].appendChild(script);
      }(document));
}
*/

/* global MathJax, jQuery */
// Leading semicolon safeguards against errors in script concatenation
// Pass dependencies into this closure from the bottom of the file
;(function($, w, Espy, undefined) {
    'use strict'; // Use EMCAScript 5 strict mode within this closure

    // Define our class on the window object under the Mathbook namespace
    var Mathbook = function(options) {

        var tocscroll_timer = null, tocDELAY = 500;  // to make ToC scrolling less jittery
        var defaults = {

            loadingClass: "mathbook-loading",
            loadedClass: "mathbook-loaded",
            sectionTrackingLoadedClass: "mathbook-section-tracking-loaded",
            stickyWrapperStuckClass: "stuck",

            // SELECTORS
            //----------
            selectors: {
                body: "body",
                primaryNavbar: "#primary-navbar",
                main: ".main",
                content: "#content",
                toc: "#toc",
                previousButton: ".previous-button",
                nextButton: ".next-button",
                sidebarLeftToggleButton: ".sidebar-left-toggle-button",
                sidebarRightToggleButton: ".sidebar-right-toggle-button",
                sidebarLeft: "#sidebar-left",
                sidebarRight: "#sidebar-right",
                sidebarLeftExtras: "#sidebar-left .extras",
                sections: "section",
                sectionLinks: "#toc a"
            },

            // BREAKPOINTS
            //--------------
            screenXsMin: 481,
            screenSmMin: 641,
            screenMdMin: 801,
            screenLgMin: 1200,

            // SECTION TRACKING
            //-----------------

            sectionHashAttribute: "id",
            sectionLinkHashAttribute: "data-scroll",

            sectionActiveClass: "active",
            sectionLinkActiveClass: "active",

            /**
            * When scrolling down...
            * Sections will be exited once their bottom edge rises above this
            * It is defined relative to the top of the screen OR the bottom
            * edge of any fixed UI elements.
            */
            enterSectionTriggerTop: 20,
            /**
            * When scrolling down...
            * Sections will be entered once their top edge rises above this
            * It is defined relative to the top of the screen OR the bottom
            * edge of any fixed UI elements.
            * This will be automatically rounded to the bottom of the screen
            * if the viewport is smaller than the defined trigger size
            */
            enterSectionTriggerBottom: 150,

            // The desired top offset of the active link in the ToC
            tocScrollToActiveOffsetTop: 100,

            // Called when the viewport enters any tracked section
            onEnterSection: null,
            // Called when the viewport exits any tracked section
            onExitSection: null,
            // Called when a section link is activated
            // This is probably the best place to log analytics
            onActivateSectionLink: null,
            // Whether or not to call onEnterSection and onExitSection for
            // sections without links.
            shouldTrackOnlyLinkedSections: false,

            /**
            * Interval upon which scrollSpy recomputes section positions
            * Should be often enough to catch DOM changes
            * but infrequent enough to be reasonably performant
            */
            scrollspyRecomputeInterval: 600, // ms

            autoScrollDuration: 400, // ms
            // linear feels mechanical, but we don't want to load jquery.ui.easing
            autoScrollEasing: "swing",

            // SIDEBAR SETTINGS
            //-----------------
            sidebarToggleDuration: 400,
            toggleButtonActiveClass: "active",
            toggleButtonInactiveClass: "",
            hasSidebarLeftClass: "has-sidebar-left",
            hasSidebarRightClass: "has-sidebar-right",
            sidebarLeftOpenClass: "sidebar-left-open",
            sidebarRightOpenClass: "sidebar-right-open",
            sidebarLeftClosedClass: "sidebar-left-closed",
            sidebarRightClosedClass: "sidebar-right-closed",
            shouldDisableSidebarTogglesAtMedium: false,
            shouldDisableSidebarTogglesAtLarge: false

        };

        // Overwrite defaults with any options passed in.
        var settings = $.extend({}, defaults, options);

        // But don't allow namespaced options to be overwritten
        // Extend them instead
        var property;
        for(property in options) {
            if( typeof options !== "undefined" &&
                options.hasOwnProperty(property) &&
                defaults.hasOwnProperty(property) &&
                $.isPlainObject(options[property]) &&
                $.isPlainObject(defaults[property]) )
            {
                settings[property] =
                    $.extend({}, defaults[property], options[property]);
            }
        }

        var self = this;
        var hashOnLoad,
            debouncedResizeDuration = 50, // ms
            debouncedResizeTimeoutId;

        // Layout stuff
        var isLayoutInitialized = false,
            _shouldSidebarsPush = false,
            isPrimaryNavbarBottom = false;

        // Sidebar stuff
        var maxOpenSidebars = 2,
            isSidebarTogglesDisabled = true,
            hasSidebarLeft,
            hasSidebarRight,
            sidebarLeftTransitionTimeoutId,
            sidebarRightTransitionTimeoutId;

        // Section stuff
        var sectionMap = {},
            isAutoScrolling = false,
            espy;

        self.$w = $(window);

        /**
         * Constructor for ToggleView objects
         * These can be used for both toggle buttons and sidebars
         */
        var ToggleView = function(options) {

            var defaults = {
                isActive: false
            };

            var settings;

            this.initialize = function(options) {
                settings = defaults;
                this.reset(options);
                this.toggle(settings.isActive);
            };

            // Private vars

            this.toggle = function(shouldActivate) {
                // If not explicitly set, toggle to opposite state
                if(typeof shouldActivate === "undefined"){
                    shouldActivate = !this.isActive();
                }

                if(shouldActivate) {
                    if(typeof this.onActivate === "function") {
                        this.onActivate.call(this.$el.get());
                    }
                    this.$el.addClass(settings.activeClass);
                    this.$el.removeClass(settings.inactiveClass);
                } else {
                    if(typeof this.onDeactivate === "function") {
                        this.onDeactivate.call(this.$el.get());
                    }

                    this.$el.addClass(settings.inactiveClass);
                    this.$el.removeClass(settings.activeClass);
                }

                settings.isActive = shouldActivate;
            };

            this.reset = function(options) {
                settings = $.extend(settings,options);
                this.$el = $(settings.el);
                this.onActivate = settings.onActivate;
                this.onDeactivate = settings.onDeactivate;
                //this.toggle(this.isActive());
            };

            this.isActive = function () {
                return settings.isActive;
            };


            // Call init
            this.initialize(options);
        };

        /**
         * Constructor for Layout objects that hold configurations for different
         * widths.
         * @param {String} debugName
         * @param {Number} minWidth
         * @param {Function} onEnter
         * @param {Function} onExit
         */
        var Layout = function(options) {
            this.minWidth = options.minWidth;
            this.debugName = options.debugName;
            this.onEnter = options.onEnter;
            this.onExit = options.onExit;

            /**
             * Called when a Layout is applied.
             */
            this.enter = function() {
                if(typeof this.onEnter === "function") {
                    this.onEnter.apply(this, arguments);
                }
            };

            /**
             * Called when a Layout is removed
             */
            this.exit = function() {
                if(typeof this.onExit === "function") {
                    this.onExit.apply(this, arguments);
                }
            };
        };

        // LAYOUT DEFINITIONS
        // IMPORTANT: MUST MATCH MEDIA QUERIES IN CSS!!!
        // Try to keep layout onEnter functions declarative in nature
        var layouts = {
            // Since layouts rely on the minWidth, add one pixel
            SMALL : new Layout({
                debugName: "small",
                minWidth: 0,
                onEnter: function(){
                    // This must come before adjusting sidebars
                    self.shouldSidebarsPush(true);

                    maxOpenSidebars = 1;
                    self.toggleSidebarLeft(false);
                    self.toggleSidebarRight(false);

                    // with primary nav on bottom
                    isPrimaryNavbarBottom = true;
                    self.initializeStickies();

                    self.sidebarTogglesDisabled(false);
                }
            }),
            MEDIUM : new Layout({
                debugName: "medium",
                minWidth: settings.screenMdMin,
                onEnter: function() {
                    // This must come before adjusting sidebars
                    self.shouldSidebarsPush(false);

                    maxOpenSidebars = 1;
                    self.toggleSidebarLeft(true);
                    self.toggleSidebarRight(false);

                    isPrimaryNavbarBottom = false;
                    self.initializeStickies();

                    if(settings.shouldDisableSidebarTogglesAtMedium) {
                        self.sidebarTogglesDisabled(true);
                    }
                }
            }),
            LARGE : new Layout({
                debugName: "large",
                minWidth: settings.screenLgMin,
                onEnter: function() {
                    // This must come before adjusting sidebars
                    self.shouldSidebarsPush(false);

                    maxOpenSidebars = 2;
                    self.toggleSidebarLeft(true);
                    self.toggleSidebarRight(true);

                    isPrimaryNavbarBottom = false;
                    self.initializeStickies();

                    if(settings.shouldDisableSidebarTogglesAtLarge) {
                        self.sidebarTogglesDisabled(true);
                    }
                }
            })
        };
        var currentLayout = layouts.LARGE;

        // Methods
        // -----------------------------------------------------------------

        /**
         * Initialize this object.
         */
        self.initialize = function() {
            hashOnLoad = w.location.hash;
            self.cacheDOMObjects();
            self.$body.addClass(settings.loadingClass);
            self.initializeSidebars();
            self.$w.resize(function() { self.resize(); });

            // Set up sticky navigation and section tracking.
            self.initializeStickies();

            self.setMathJaxOverrides();

            self.resize();
            self.scrollTocToActiveItem();
            self.$body.addClass(settings.loadedClass);
            self.$body.removeClass(settings.loadingClass);
        };

        /**
         * Caches all the DOM Objects we need, with JQuery
         */
        self.cacheDOMObjects = function() {
            self.$w = $(w);

            var property;
            for(property in settings.selectors) {
                if(settings.selectors.hasOwnProperty(property)) {
                    var prefixed = "$" + property;
                    self[prefixed] = $(settings.selectors[property]);
                }
            }

            // Cache values
            hasSidebarLeft = self.hasSidebarLeft();
            hasSidebarRight = self.hasSidebarRight();
        };



        /**
        * By default, MathJax scrolls the window to the hash location
        * after "End Typeset" event. We need to override this functionality
        * so things work nicely with our sticky header
        */
        self.setMathJaxOverrides = function() {
            if(typeof MathJax !== "undefined") {
              var mjvers = MathJax.version;
              mjvers = parseFloat(mjvers.substring(0,3));
              console.log("MathJax version", mjvers);
              if (mjvers < 3) {
                // Before MathJax applies the page's configuration
                MathJax.Hub.Register.StartupHook("Begin Config", function() {
                    // Modify that configuration to apply overrides
                    MathJax.Hub.Config({
                        positionToHash: false
                    });
                });

                // when MathJax is finished rendering,
                MathJax.Hub.Register.StartupHook("End Typeset", function () {
                    self.postMathJax();
                });
              } else {  // need to actually do something for MJ3
                self.postMathJax();
              }
            } else {
                self.postMathJax();
            }
        };

        self.postMathJax = function() {
            // we handle the hash positioning so that it lines up
            // nicely with our fixed header
      // I am disabling the TOC scrolling because changes in jQuery 3 are
      // incompatible with Espy and I have not been able to figure out
      // how to fix it.  David Farmer 1/1/19
      // Update 1/28/19  The first and 3rd are okay now, because of a
      // fix starting at line 104 of the espy code.
      // still not sure what is up with the 2nd one
            self.initializeSectionTracking();
  //          self.scrollToSection(hashOnLoad.substr(1));
            self.$body.addClass(settings.sectionTrackingLoadedClass);

            // TODO expand knowl from hash if there's a match?
        };


        /**
         * Initializes the sticky navigation
         */
        self.initializeStickies = function() {

            var primaryNavbarHeight = self.$primaryNavbar.outerHeight();

            self.$primaryNavbar.unstick();

            // Stick navbar stuff
            if(!isPrimaryNavbarBottom){
                self.$primaryNavbar.sticky({
                    className: settings.stickyWrapperStuckClass,
                    wrapperClassName:"navbar",
                    topSpacing: 0,
                });

                // Update the position in case scroll is already below
                // the stickyifying point
                self.$primaryNavbar.sticky("update");
            }

            // Stick left sidebar
            if(hasSidebarLeft) {
                self.$sidebarLeft.unstick();

                // If primaryNavbar is top, offset sidebar by it's height,
                // else offset zero
                var sidebarLeftTopSpacing =
                    isPrimaryNavbarBottom ? 0 : primaryNavbarHeight;

                self.$sidebarLeft.sticky({
                    className: settings.stickyWrapperStuckClass,
                    wrapperClassName:"sidebar",
                    topSpacing : sidebarLeftTopSpacing
                });

                self.$sidebarLeftStickyWrapper = self.$sidebarLeft.parent();
                self.resizeSidebarLeftStickyWrapper();

                // Update the position in case scroll is already below
                // the stickyifying point
                self.$sidebarLeft.sticky("update");
            }
        };

        ////////////////////////////////////////////////////////////////////////////
        // SECTIONS / NAV
        ////////////////////////////////////////////////////////////////////////////

        self.initializeSectionTracking = function() {
            espy = new Espy(w, self.onSectionStateChange);
            self.reconfigureEspy();

            // Generate a map for all linked sections
            self.$sections.each(function() {
                var $section = $(this);
                var hash = $section.attr(settings.sectionHashAttribute);


                // Find the corresponding link
                var linkSelector =
                        "["+settings.sectionLinkHashAttribute+"='"+hash+"']";
                var $link = self.$sectionLinks.filter(linkSelector);

                // If this section has a link
                if($link.length > 0) {
                    // Create an entry in our section map
                    sectionMap[hash] = {
                        $section: $section,
                        $link: $link,
                        isActive: false
                    };

                    $link.on("click", self.onSectionLinkClick);

                    if(settings.shouldTrackOnlyLinkedSections) {
                        // Add them one at a time
                        espy.add($section);
                    }
                }
            });

            if(!settings.shouldTrackOnlyLinkedSections) {
                // Add all sections to tracking all at once
                espy.add(self.$sections);
            }

            // When the dom changes, espy needs to recompute the positions
            // of all the sections. It seems unreasonable, in this case,
            // to expect people to call the refresh method everytime the DOM
            // changes, so we will resort to an interval.
            setInterval(function(){
                // Only worth updating if ToC is visible
                if(!self.isSidebarLeftClosed()) {
                   self.refreshEspy();
                }
            }, settings.spyscrollRecomputeInterval);

        };

        self.reconfigureEspy = function() {
            // Espy's offset is the offset to the top edge of the trigger
            // We want to configure the offset from the top edge of the screen
            // to the bottom edge of the trigger
            var espyOptions = {};
            var navbarHeight = (self.$primaryNavbar.outerHeight() || 0);
            var activeArea = (self.$w.innerHeight() || 0) - navbarHeight;

            // Compute offset from top of screen
            espyOptions.offset = navbarHeight + settings.enterSectionTriggerTop;

            // Compute size of trigger
            espyOptions.size = settings.enterSectionTriggerBottom -
                           settings.enterSectionTriggerTop;
            // Limit size to the size of the activeArea
            espyOptions.size = Math.min(activeArea, espyOptions.size);
            // To be safe, don't allow negative
            espyOptions.size = Math.max(espyOptions.size, 0);

            // the espy.configure() was there from the beginning, but gave an error that espy was not known
            // so I added the next line --DF
            espy = new Espy(w, self.onSectionStateChange);
            espy.configure(espyOptions);
        };

        self.refreshEspy = function() {
            // the espy.reload() was there from the beginning, but gave an error that espy was not known
            // so I added the next line --DF
     //       espy = new Espy(w, self.onSectionStateChange);
            espy.reload();
        };

        self.onSectionLinkClick = function(e) {
            // Called in the context of the link node
            var hash = $(this).attr(settings.sectionLinkHashAttribute);
            var success =
                self.scrollToSection(hash, self.updateLinks, self, [hash]);

            // If sidebars are set to push
            if(self.shouldSidebarsPush()) {
                // then we should automatically close the sidebar
                self.toggleSidebarLeft(false);
            }

            if(success) {
                e.preventDefault();
            }
        };

        self.scrollTocToActiveItem = function(duration) {
            var $activeItems =
                self.$toc.find("." + settings.sectionLinkActiveClass);

            if($activeItems.length > 0) {
                // Scroll to the last of the active links
                self.scrollTocToItem($activeItems.last(), duration);
            }
        };

        /**
         * This function assumes the toc has relative or absolute positioning.
         */
        self.scrollTocToItem = function(element, duration) {
            if(typeof duration === "undefined") {
                duration = settings.autoScrollDuration;
            }

            var $item = $(element);
            // IF the given item is in the toc
            if($item.parents().filter(self.$toc).length > 0) {
                // The offset from the top of the toc is the difference
                // between the offsets from the top of the document
                var tocDocumentTopOffset = self.$toc.position().top;
                var itemDocumentTopOffset = $item.position().top;
                var itemTocTopOffset =
                    itemDocumentTopOffset - tocDocumentTopOffset;

                // targeted offset between top of frame and active item
                var scrollOffset = settings.tocScrollToActiveOffsetTop;

                var targetScrollTop =
                    self.$toc.scrollTop() + itemTocTopOffset - scrollOffset;

                var maxScrollTop =
                    self.$toc.prop('scrollHeight') - (self.$toc.innerHeight() || 0);

                // Apply limits
                targetScrollTop = Math.max(targetScrollTop,0);
                targetScrollTop = Math.min(targetScrollTop, maxScrollTop);


                // When you scroll quickly down the page, the ToC scrolling can become jittery.
                // So, we don't scroll until things have settled down
                clearTimeout(tocscroll_timer);
                tocscroll_timer = setTimeout(function() {

                    self.$toc.animate({
                        scrollTop: targetScrollTop
                    },
                    duration,
                    settings.autoScrollEasing);

                }, tocDELAY);

            }
        };

        // Animated scroll to a section
        // Returns false if no section to scroll to on this page
        self.scrollToSection = function(hash, callback, scope, params) {
            var sectionExists = false;
            var selector = "#" + hash;
            var $matchedSection = $(selector).first();

            if($matchedSection.length > 0) {
                isAutoScrolling = true;

                var targetOffsetTop = $matchedSection.offset().top;

                var uiHeight =
                    isPrimaryNavbarBottom ? 0 : self.$primaryNavbar.outerHeight();

                // Subtract screen offset for entering sections
                targetOffsetTop += -(settings.enterSectionTriggerTop) + 1;
                // Subtract UI element heights
                targetOffsetTop += -(uiHeight);
                // Add fudge so we do, in fact, enter the section
                targetOffsetTop += 1;

                // Limit to positive numbers
                var targetScrollTop = Math.max(targetOffsetTop, 0);

                // Define some things we need to do after scrolling
                var wrappedCallback = function() {
                    isAutoScrolling = false;
                    if(callback && typeof callback === "function") {
                        callback.call(scope, params);
                    }
                };

                // Perform the scroll
                $('body,html').animate({
                        scrollTop: targetScrollTop
                    },
                    settings.autoScrollDuration,
                    settings.autoScrollEasing,
                    wrappedCallback);

                sectionExists = true;
            }

            // Return false if no section to scroll to on this page
            return sectionExists;
        };

        self.onSectionStateChange = function(isEntered, state) {
            /*jshint unused:false */

            // Called with the element Node's context
            var element = this;
            var $section = $(element);

            var hash = $section.attr(settings.sectionHashAttribute);
            if(sectionMap.hasOwnProperty(hash)) {
                sectionMap[hash].isActive = isEntered;
            }

            // Don't update links during auto scrolls
            // It just slows things down
            if(!isAutoScrolling) {
                self.updateLinks();
            }

            if(isEntered) {
                $section.addClass(settings.sectionActiveClass);
                if(typeof settings.onEnterSection === "function"){
                    settings.onEnterSection.apply(element, arguments);
                }
                window.thefocus = element.id;
            } else {
                $section.removeClass(settings.sectionRemoveClass);
                if(typeof settings.onExitSection === "function"){
                    settings.onEnterSection.apply(element, arguments);
                }
            }

        };

        self.updateLinks = function() {
            var deepestHash = null;
            // for all sections in document order
            self.$sections.each(function() {
                var $section = $(this);
                var hash = $section.attr(settings.sectionHashAttribute);
                if(sectionMap.hasOwnProperty(hash)) {
                    if(sectionMap[hash].isActive) {
                        deepestHash = hash;
                    }
                }
            });
            if(deepestHash !== null) {
                var $link = sectionMap[deepestHash].$link;
                if(!$link.hasClass(settings.sectionLinkActiveClass)) {
                    self.$sectionLinks.removeClass(settings.sectionLinkActiveClass);
                    $link.addClass(settings.sectionLinkActiveClass);
                    if(settings.onActivateSectionLink === "function") {
                        settings.onActivateSectionLink.call($link.get());
                    }
           // We have temporarily disabled setHash because the scrolling
           // to the target section does not work properly.
           // The scrolling of the TOC still works okay.
               //     self.setHash(deepestHash);
                    self.scrollTocToActiveItem();
                }
            }
        };

        // Set the hash to reflect the current position in the page
        // This function temporarily removes the anchor matching this
        // hash so that the page doesn't jump as we change the hash
        // It's sort of expensive, so don't call it needlessly
        self.setHash = function(hash) {
            if(hash === w.location.hash.substr(1)) {
                return;
            }

            if(settings.pushHistory && history.pushState) {
                history.pushState({}, hash, "#" + hash);
            } else if(history.replaceState) {
                history.replaceState({}, hash, "#" + hash);
            } else if(settings.provideHistoryFallback) {
                // we do it the hacky way
                var $fx;
                var $nodes = $( '#' + hash + ',[name=\"' + hash + '\"]' );
                var ids = [];
                var names = [];

                var i = 0;
                // Remove id and name from all matched nodes
                $nodes.each(function() {
                    var node = $(this);
                    ids[i] = node.attr('id');
                    names[i] = node.attr('name');
                    node.attr( 'id', '' );
                    node.attr( 'name', '' );
                    i++;
                });

                if($nodes.length) {
                    // Some browsers will try to scroll to where the element
                    // was last seen, so we create a dummy
                    $fx = $( '<div></div>' )
                            .css({
                                    position:'absolute',
                                    visibility:'hidden',
                                    top: self.$w.scrollTop() + 'px'
                                })
                            .attr( 'id', hash )
                            .appendTo( document.body );
                }

                // finally, set the hash
                document.location.hash = hash;

                i = 0;
                // Return ids and names to matched nodes
                $nodes.each(function() {
                    var node = $(this);
                    node.attr( 'id', ids[i] );
                    node.attr( 'name', names[i] );
                    i++;
                });

                // Remove our dummy
                if($nodes.length) {
                    $fx.remove();
                }
            }
        };

        ////////////////////////////////////////////////////////////////////////////
        // SIDEBARS
        ////////////////////////////////////////////////////////////////////////////

        /**
         * Initializes SidebarViews and registers listeners
         */
        self.initializeSidebars = function() {
            if(hasSidebarLeft) {
                self.sidebarLeftToggleButtonView = new ToggleView({
                    el: self.$sidebarLeftToggleButton,
                    activeClass: settings.toggleButtonActiveClass,
                    inactiveClass: settings.toggleButtonInactiveClass,
                });
                self.sidebarLeftView = new ToggleView({
                    el: self.$body, // We want classes to be applied here
                    activeClass : settings.sidebarLeftOpenClass,
                    inactiveClass :settings.sidebarLeftClosedClass,
                    onActivate: function() {
                        self.onSidebarOpen();
                    },
                    onDeactivate: function() {
                        self.onSidebarClose();
                    }
                });
            }

            if(hasSidebarRight) {
                self.sidebarRightToggleButtonView = new ToggleView({
                    el: self.$sidebarRightToggleButton,
                    activeClass: settings.toggleButtonActiveClass,
                    inactiveClass: settings.toggleButtonInactiveClass,
                });
                self.sidebarRightView = new ToggleView({
                    el: self.$body, // We want classes to be applied here
                    activeClass : settings.sidebarRightOpenClass,
                    inactiveClass :settings.sidebarRightClosedClass,
                    onActivate: function() {
                        self.onSidebarOpen();
                    },
                    onDeactivate: function() {
                        self.onSidebarClose();
                    }
                });
            }

            self.sidebarTogglesDisabled(false);
        };

        self.sidebarTogglesDisabled = function(isDisabled) {
            if(typeof isDisabled === "undefined") {
                return isSidebarTogglesDisabled;
            }

            if(isDisabled !== isSidebarTogglesDisabled) {
                if(!isDisabled) {
                    if(hasSidebarLeft) {
                        self.$sidebarLeftToggleButton
                            .on("click", function(e) {
                                self.toggleSidebarLeft();
                            });
                    }

                    if(hasSidebarRight) {
                        self.$sidebarRightToggleButton
                            .on("click", function(e) {
                                self.toggleSidebarRight();
                            });
                    }
                } else {
                    if(hasSidebarLeft) {
                        self.$sidebarLeftToggleButton.off("click");
                    }

                    if(hasSidebarRight) {
                        self.$sidebarRightToggleButton.off("click");
                    }
                }

                isSidebarTogglesDisabled = true && isDisabled;
            }

        };

        // TODO combine left and right toggle functions?

        /**
         * Toggles the left sidebar to the shouldOpen state
         * or the reverse of the current state if shouldOpen is undefined.
         * @param shouldOpen {Boolean}
         */
        self.toggleSidebarLeft = function(shouldOpen) {
            if(hasSidebarLeft) {
                if(typeof shouldOpen === "undefined") {
                    shouldOpen = self.isSidebarLeftClosed();
                }

                // Impose max sidebars limit
                if(shouldOpen &&
                   maxOpenSidebars === 1 &&
                   !self.isSidebarRightClosed()
                ){
                    self.toggleSidebarRight(false);
                }

                // If we are opening
                if(shouldOpen) {
                    // Scroll toc to active link without animation
                    self.scrollTocToActiveItem(0);
                }

                self.sidebarLeftToggleButtonView.toggle(shouldOpen);
                self.sidebarLeftView.toggle(shouldOpen);

                // We might need to do some things at transition end
                // Cancel the current timeout, if there is one
                clearTimeout(sidebarLeftTransitionTimeoutId);
                // Set a new one
                sidebarLeftTransitionTimeoutId = setTimeout(function() {
        //            self.refreshEspy();

                }, settings.sidebarTransitionDuration);
            }
        };

        /**
         * Toggles the right sidebar to the shouldOpen state
         * or the reverse of the current state if shouldOpen is undefined.
         * @param shouldOpen {Boolean}
         */
        self.toggleSidebarRight = function(shouldOpen) {
            if(hasSidebarRight) {
                if(typeof shouldOpen === "undefined") {
                    shouldOpen = self.isSidebarRightClosed();
                }
                if(shouldOpen &&
                   maxOpenSidebars === 1 &&
                   !self.isSidebarLeftClosed()
                ){
                    self.toggleSidebarLeft(false);
                }
                self.sidebarRightToggleButtonView.toggle(shouldOpen);
                self.sidebarRightView.toggle(shouldOpen);

                // We might need to do some things at transition end
                // Cancel the current timeout, if there is one
                clearTimeout(sidebarRightTransitionTimeoutId);
                // Set a new one
                sidebarRightTransitionTimeoutId = setTimeout(function() {
                    self.refreshEspy();
                }, settings.sidebarTransitionDuration);
            }
        };

        /**
         * Returns true if the left sidebar is present in HTML
         * Use the cached variable instead of this function.
         */
        self.hasSidebarLeft = function() {
            // To be safe, we'll require everything
            return self.$sidebarLeft.length > 0 &&
                   self.$sidebarLeftToggleButton.length > 0 &&
                   self.$main.length > 0;
        };

        /**
         * Returns true if the right sidebar is present in HTML
         * Use the cached variable instead of this function.
         */
        self.hasSidebarRight = function() {
            // To be safe, we'll require everything
            return self.$sidebarRight.length > 0 &&
                   self.$sidebarRightToggleButton.length > 0 &&
                   self.$main.length > 0;
        };

        /**
         * Sets whether sidebars should push or slide when opening.
         * Push fixes the width of the main content and moves it aside.
         * Slide subtracts the sidebar's width from the main width.
         *
         * @param shouldPush {Boolean} true to push, false to slide
         */
        self.shouldSidebarsPush = function(shouldSidebarsPush) {
            if(typeof shouldSidebarsPush === "undefined") {
                return _shouldSidebarsPush;
            }
            _shouldSidebarsPush = shouldSidebarsPush;

            if(!_shouldSidebarsPush) {
                self.unlockMainWidth();
            }
        };

        /**
         * Called when a sidebar begins pushing
         */
        self.onSidebarOpen = function () {
            if(self.shouldSidebarsPush()) {
                self.lockMainWidth();
            }
        };

        /**
         * Called when a sidebar closes
         */
        self.onSidebarClose = function() {
            if(self.shouldSidebarsPush()) {
                // Unlock the main element width only if both sidebars are closed.
                if(self.isSidebarRightClosed() && self.isSidebarLeftClosed()){
                    self.unlockMainWidth();
                }
            }
        };

        /**
         * Returns true if right sidebar is closed or non-existant
         */
        self.isSidebarRightClosed = function() {
            return (!hasSidebarRight || !self.sidebarRightView.isActive());
        };

        /**
         * Returns true if left sidebar is closed or non-existant
         */
        self.isSidebarLeftClosed = function() {
            return (!hasSidebarLeft || !self.sidebarLeftView.isActive());
        };

        /**
         * Locks the main element at it's current width
         */
        self.lockMainWidth = function() {
            self.$main.width(self.$main.width());
        };

        /**
         * Unlocks the main element width
         */
        self.unlockMainWidth = function() {
            self.$main.width("");
        };

        ////////////////////////////////////////////////////////////////////////////
        // RESIZING METHODS
        ////////////////////////////////////////////////////////////////////////////

        /**
         * Called when the browser resizes
         */
        self.resize = function() {
            var navbarHeight,
                activeAreaHeight,
                newLayout;

            var windowWidth = viewport().width;
            var windowHeight = self.$w.height();

            // Update the layout if necessary
            newLayout = self.findLayout(windowWidth);
            if(!isLayoutInitialized || newLayout !== currentLayout) {
                isLayoutInitialized = true;
                self.setLayout(newLayout);
            }

            // set toc height to fill window
            navbarHeight = self.$primaryNavbar.outerHeight();
            activeAreaHeight = windowHeight - navbarHeight;

            var isSidebarOpen =
                !self.isSidebarLeftClosed() || !self.isSidebarRightClosed();
            if(self.shouldSidebarsPush() && isSidebarOpen) {
                self.$main.width(windowWidth);
            }

            self.resizeContent(activeAreaHeight);
            self.resizeToc(activeAreaHeight);
            self.resizeSidebarLeftStickyWrapper();

            // Debounce things that only have to happen at the end of the resize
            // This improves the resize performance
            clearTimeout(debouncedResizeTimeoutId);
            debouncedResizeTimeoutId =
                setTimeout(self.debouncedResize, debouncedResizeDuration);

        };

        /**
         * Gets the viewport dimensions that are used to evaluate
         * media queries.
         * This is different than jQuery's width/height functions.
         * Adapted from: http://stackoverflow.com/a/11310353/1599617
         */
        function viewport() {
            var e = window, a = 'inner';
            if (!('innerWidth' in window )) {
                a = 'client';
                e = document.documentElement || document.body;
            }
            return { width : e[ a+'Width' ] , height : e[ a+'Height' ] };
        }

        /**
         * Actions that only need to occur at the end of a resize.
         * We debounce this actions since many browsers fire lots of resize
         * events and we don't want to slow down the resize by doing this stuff
         */
        self.debouncedResize = function() {
            self.reconfigureEspy();
            self.scrollTocToActiveItem();
        };

        /**
         * Fixes the minHeight of the content
         */
        self.resizeContent = function(activeAreaHeight) {
            // Force the content to be at least as tall as the viewport.
            self.$content.css({'minHeight': activeAreaHeight });
        };

        /**
         * Fixes the height of the ToC
         */
        self.resizeToc = function(activeAreaHeight) {
            // The height of the left sidebar extras box if it exists
            var extrasHeight = 0;
            if(self.$sidebarLeftExtras.length !== 0) {
                extrasHeight = self.$sidebarLeftExtras.outerHeight();
            }

            // Force the toc to fill whatever space remains in sidebar
            // ...but leave room for an "extras" box if it exists
            var tocHeight = activeAreaHeight - extrasHeight;
            self.$toc.height(tocHeight);
        };

        /**
         * Fixes the sidebarLeftStickyWrapper if it exists
         */
        self.resizeSidebarLeftStickyWrapper = function() {
            var newHeight;
            if(self.hasOwnProperty("$sidebarLeftStickyWrapper")) {
                // The height should be no greater than the content
                newHeight = self.$sidebarLeft.outerHeight();
                newHeight = Math.min(newHeight, self.$content.outerHeight());
                self.$sidebarLeftStickyWrapper.height(newHeight);
            }
        };

        /**
         * Returns the correct layout for given browser width
         * @param width {Number} browser width
         * @return {Layout} the layout to apply
         */
        self.findLayout= function(viewportWidth) {
            var newLayout = null;
            for (var property in layouts) {
                if (layouts.hasOwnProperty(property)) {
                    var layout = layouts[property];
                    // If current viewportWidth is in layout range
                    // and layout.minwidth is bigger than any other match
                    if(viewportWidth >= layout.minWidth &&
                       (newLayout === null || layout.minWidth > newLayout.minWidth))
                    {
                        // then this is our best match yet.
                        newLayout = layout;
                    }
                }
            }
            return newLayout;
        };

        /**
         * Sets the current layout
         * @param newLayout {Layout} the layout to apply
         */
        self.setLayout = function(newLayout) {
            if(newLayout.constructor !== Layout) {
                throw new Error(
                        "setLayout::newLayout must be of type Layout");
            }

            currentLayout.exit();
            newLayout.enter();

            currentLayout = newLayout;
        };

        // Run init when we are constructed
        self.initialize();
    };

    // If script is run after page is loaded, initialize immediately
    if(document.readyState === "complete") {
        w.mathbook = new Mathbook({});
    } else {
        // wait and init when the DOM is fully loaded
        $(window).on("load", function() {
            w.mathbook = new Mathbook();
        });
    }

    return Mathbook;

})(jQuery, window, jQuery.Espy);

