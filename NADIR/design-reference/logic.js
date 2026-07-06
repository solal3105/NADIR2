// Référence : logique du design NADIR.dc.html (script data-dc-script),
// transcrite depuis claude.ai/design — sert de source de vérité pour le port Swift.
// Props: defaultCity (string), reduceMotion (bool), previewOnboarding (bool).

class Component extends DCLogic {
  constructor(props){
    super(props);
    this.chartRef = React.createRef();
    this.cityRef = React.createRef();
    this.obCityRef = React.createRef();
    this._firstDraw = true;
    let prof=null; try{ prof=JSON.parse(localStorage.getItem('nadir.profile.v1')||'null'); }catch(e){}
    this._prof = prof;
    const onboarded = !!(prof && prof.onboarded);
    this.state = { tab:'today', Ti:26,
      mass:(prof&&prof.mass)||'moy', air:(prof&&prof.air)||'moy', expo:(prof&&prof.expo)||'sud', expo2:(prof&&prof.expo2)||null,
      lat:(prof&&typeof prof.lat==='number')?prof.lat:null, lon:(prof&&typeof prof.lon==='number')?prof.lon:null,
      raw:this.demoData(), status:'',
      alarmStart:!!(prof&&prof.alarmStart), alarmEnd:!!(prof&&prof.alarmEnd),
      onboarding:!onboarded, obStep:0, obStatus:'' };
  }

  C(){ return { HOT:"#ff3b1d", COLD:"#3ea6ff", GO:"#5ad17a", DIM:"#8c8c8c", FAINT:"#5a5a5a", LINE:"#2a2a2a", INK:"#fff" }; }
  pad2(n){ return String(n).padStart(2,"0"); }
  fmt1(v){ return v.toFixed(1).replace(".", ","); }
  hourLabel(d){ return this.pad2(d.getHours())+"h"; }
  avg(a){ return a.reduce((s,x)=>s+x,0)/a.length; }

  demoData(){
    const now=new Date(); now.setMinutes(0,0,0);
    const times=[],temp=[],dew=[];
    for(let k=-1;k<33;k++){ const dd=new Date(now.getTime()+k*3600e3);
      const h=dd.getHours()+dd.getMinutes()/60;
      times.push(dd); temp.push(+(26-8*Math.cos(2*Math.PI*(h-5)/24)).toFixed(1)); dew.push(12); }
    return {times,temp,dew,place:"Exemple",demo:true};
  }
  async geocode(city){
    const r=await fetch(`https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(city)}&count=1&language=fr&format=json`);
    const j=await r.json();
    if(!j.results||!j.results.length) throw new Error("introuvable");
    const g=j.results[0];
    return {lat:g.latitude, lon:g.longitude, name:g.name+(g.country_code?" ("+g.country_code+")":"")};
  }
  async forecast(lat, lon, name){
    const u=`https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&hourly=temperature_2m,dew_point_2m&forecast_days=3&timezone=auto`;
    const j=await (await fetch(u)).json();
    return { times:j.hourly.time.map(t=>new Date(t)), temp:j.hourly.temperature_2m, dew:j.hourly.dew_point_2m, place:name, demo:false };
  }
  nextDay(){
    const raw=this.state.raw, now=new Date();
    let i0=raw.times.findIndex(t=>t>=now); if(i0<0)i0=0; i0=Math.max(0,i0-1);
    const n=Math.min(30, raw.times.length-i0);
    return { times:raw.times.slice(i0,i0+n), temp:raw.temp.slice(i0,i0+n), dew:raw.dew.slice(i0,i0+n), place:raw.place, demo:raw.demo };
  }

  simIndoor(d, mass, air){
    const Ti=this.state.Ti, expo=this.state.expo, expo2=(this.state.expo2&&this.state.expo2!==this.state.expo)?this.state.expo2:null;
    const A_FL=20, VOL=50, RHOCP=1206, CAIR=150000;
    const KAPPA={leg:110000,moy:165000,lou:260000}, ACH={fai:3,moy:8,for:15};
    const HAM=300, HENV=50, QINT=150, QSOL=650, QDIF=120, SHADE=0.3, SUB=10, OPEN_TH=0.75, CLOSE_TH=0.25;
    // Double exposition (logement traversant) : le vitrage se répartit sur deux façades,
    // et surtout un courant d'air peut traverser d'un côté à l'autre.
    const dual=!!expo2, OPP={nord:'sud',sud:'nord',est:'ouest',ouest:'est'};
    const facades=dual?[expo,expo2]:[expo];
    const perFace=dual?0.6:1.0;                            // vitrage réparti : ~0.6x par façade
    const crossMult=dual?(OPP[expo]===expo2?1.8:1.5):1.0;  // courant d'air : maximal si façades opposées
    const HENVe=HENV*(dual?1.15:1);                        // deux murs extérieurs : échange un peu plus
    const n=d.temp.length, Cm=KAPPA[mass]*A_FL, Hv=RHOCP*ACH[air]*crossMult*VOL/3600, dt=3600/SUB;
    // Apport solaire horaire selon l'orientation : composante directe sur chaque façade
    // (pic 9h à l'est, 13h au sud, 17h30 à l'ouest, rien au nord) + diffus pour tous.
    const bell=(h,pk,w)=>{ const x=Math.abs(h-pk); return x>=w?0:Math.pow(Math.cos(Math.PI/2*x/w),2); };
    const PK={est:9, sud:13, ouest:17.5}, WD={est:4, sud:4.5, ouest:4.5};
    const solRaw=h=>QDIF*(dual?1.2:1)*bell(h,13.5,7.5) + facades.reduce((a,f)=>a+(f==='nord'?0:QSOL*perFace*bell(h,PK[f],WD[f])),0);
    const Q0=QINT + SHADE*solRaw(d.times[0].getHours());
    let Ta=Ti, Tm=Ti - (HENVe*(d.temp[0]-Ti) + Q0)/HAM;
    let isOpen=false; const T=[Ta], open=[];
    for(let i=0;i<n;i++){
      // Ouvrir n'a d'intérêt que si le refroidissement par l'air dépasse le soleil
      // supplémentaire admis fenêtre ouverte : pénalité exprimée en degrés équivalents.
      const dTsol=(1-SHADE)*solRaw(d.times[i].getHours())/Hv;
      if(isOpen){ if(d.temp[i] > Ta - CLOSE_TH - dTsol) isOpen=false; }
      else { if(d.temp[i] < Ta - OPEN_TH - dTsol) isOpen=true; }
      open.push(isOpen);
      if(i===n-1) break;
      const Q=QINT + (isOpen?1:SHADE)*solRaw(d.times[i].getHours());
      const Hao=HENVe+(isOpen?Hv:0);
      for(let s=0;s<SUB;s++){
        const dTa=(dt/CAIR)*(Hao*(d.temp[i]-Ta)+HAM*(Tm-Ta)+Q);
        const dTm=(dt/Cm)*(HAM*(Ta-Tm));
        Ta+=dTa; Tm+=dTm;
      }
      T.push(Ta);
    }
    return {T, open};
  }
  peakDrop(d,mass,air,pM){ return Math.max(0, d.temp[pM]-this.simIndoor(d,mass,air).T[pM]); }

  compute(){
    if(!this.state.raw) return null;
    const d=this.nextDay(), n=d.temp.length;
    const sim=this.simIndoor(d, this.state.mass, this.state.air), indoor=sim.T, open=sim.open;
    const runs=[]; let s=-1;
    for(let i=0;i<n;i++){ if(open[i]){ if(s<0)s=i; } else if(s>=0){ runs.push([s,i-1]); s=-1; } }
    if(s>=0) runs.push([s,n-1]);
    let mi=0; for(let i=1;i<n;i++) if(d.temp[i]<d.temp[mi]) mi=i;
    const p0=runs.length?runs[0][0]:0;
    let pM=p0; for(let i=p0+1;i<n;i++) if(d.temp[i]>d.temp[pM]) pM=i;
    return {d,n,indoor,open,runs,mi,pM};
  }

  effRows(comp){
    const {d,pM}=comp, M=this.state.mass, A=this.state.air;
    const total=this.peakDrop(d,M,A,pM), base=this.peakDrop(d,"leg","fai",pM);
    const mE=Math.max(0, this.peakDrop(d,M,"fai",pM)-base);
    const aE=Math.max(0, this.peakDrop(d,"leg",A,pM)-base);
    const syn=Math.max(0, total-base-mE-aE);
    const massLab={leg:"légers",moy:"moyens",lou:"lourds"}[M];
    const airLab={fai:"faible",moy:"moyenne",for:"forte"}[A];
    const SC=8;
    const raw=[
      {lab:"ouvrir au bon moment", val:base},
      {lab:`murs ${massLab}`, val:mE},
      {lab:`ventilation ${airLab}`, val:aE},
    ];
    if(syn>=0.15) raw.push({lab:"les deux combinés", val:syn});
    return { rows: raw.map(r=>({lab:r.lab, val:this.fmt1(r.val)+"°C de moins", pct:Math.min(100,r.val/SC*100).toFixed(0)+"%"})), total: this.fmt1(total)+"°C de moins que dehors" };
  }

  verdict(comp){
    const {d,mi,pM,runs,indoor,open}=comp, Ti=this.state.Ti;
    const coolT=d.temp[mi].toFixed(0), coolH=this.hourLabel(d.times[mi]);
    const out={ demo:d.demo, place:d.place, hasWindow:runs.length>0, coolH, coolT, peakH:this.hourLabel(d.times[pM]) };
    if(!runs.length){
      out.big="Gardez fermé";
      out.sub="Restez fermé. Attendez une nuit plus fraîche.";
      out.closedTi=Ti.toFixed(0);
    } else {
      const endOf=r=>this.pad2((d.times[r[1]].getHours()+1)%24)+"h";
      const fmt=r=>`de ${this.hourLabel(d.times[r[0]])} à ${endOf(r)}`;
      const first=runs[0], second=runs[1];
      out.big = open[0] ? `Ouvrez jusqu'à ${endOf(first)}` : `Ouvrez ${fmt(first)}`;
      let miIn=0; for(let i=1;i<indoor.length;i++) if(indoor[i]<indoor[miIn]) miIn=i;
      out.nightMin=indoor[miIn].toFixed(0);
      out.cooler=this.fmt1(d.temp[pM]-indoor[pM]);
      out.second = second ? fmt(second) : null;
      const dws=[]; for(let i=0;i<open.length;i++) if(open[i]) dws.push(d.dew[i]);
      out.humid = dws.length && this.avg(dws)>16;
    }
    return out;
  }

  // renderChart : W=390, H=300, P={l:44,r:18,t:22,b:36} ; ordre de dessin :
  // bandes vertes (fadein) ; gridlines temp (pas 5/4/2 selon span>18/9) + labels "N°" mono10 DIM à gauche (x=P.l-6, anchor end) ;
  // aire bleue max(dehors,indoor)->indoor rgba(62,166,255,0.14) (fadein) ;
  // ticks horaires tous les 3 (ligne 4px #2a2a2a, label mono10 DIM à H-b+15) ;
  // minuit : dash 3 5 rgba(255,255,255,0.14) + label "demain" mono9 à (x+5, H-b-8), une seule fois ;
  // gradient sous indoor (COLD 0.20 -> 0) ; halo indoor 10px@0.10 + 5px@0.18 (fadein) ;
  // dehors rgba(255,255,255,0.34) 1.5px (tracé animé) ; indoor COLD 2.6px (tracé animé, delay .85s) ;
  // labels fin de courbe "dehors" (blanc .6) / "chez vous" (COLD) mono11, séparés de 16px min ;
  // cote au pic si gap>0.6 : ligne + 2 traverses ±4px blanc 1.5, label fmt1(gap)+" °C plus frais" mono11, côté selon bx>W-140 ;
  // min dehors : cercle r3.5 blanc .55 + "min N°" mono10 DIM à (mx, my+15) ;
  // maintenant : ligne verticale blanche .35 à X(0) + label mono10 DIM (X(0)+4, P.t+10) ;
  // lieu : mono11 INK en haut à droite (W-P.r, P.t+10).
  // Animations CSS : tnDraw 1.3s .1s cubic-bezier(.4,0,.2,1) ; tnFade .8s .9s ; indoor draw delay .85s.
  // reduceMotion (prop) => pas d'animation. _firstDraw repasse à true à chaque nouvelle source météo.

  componentDidMount(){ this.renderChart(); this._onResize=()=>this.renderChart(); window.addEventListener('resize', this._onResize);
    if(this.props && this.props.previewOnboarding){ this.setState({onboarding:true, obStep:0, obStatus:''}); }
    if(this.state.lat!=null && this.state.lon!=null){ this.loadLoc(this.state.lat, this.state.lon, (this._prof&&this._prof.place)||'Votre logement'); }
    else{ const c=((this.props && this.props.defaultCity)||"").trim(); if(c) this.bootCity(c); }
  }
  async loadLoc(lat,lon,place){
    try{ this.setState({status:"Récupération de la météo…"});
      const raw=await this.forecast(lat,lon,place); this._firstDraw=true; this.setState({raw, status:""});
    }catch(e){ this.setState({status:"Météo indisponible."}); }
  }
  persist(patch){
    let cur={}; try{ cur=JSON.parse(localStorage.getItem('nadir.profile.v1')||'{}')||{}; }catch(e){}
    const s=this.state;
    const prof={ onboarded:cur.onboarded||false, mass:s.mass, air:s.air, expo:s.expo, expo2:s.expo2||null, lat:s.lat, lon:s.lon, place:(s.raw&&s.raw.place)||cur.place||'', alarmStart:!!s.alarmStart, alarmEnd:!!s.alarmEnd };
    Object.assign(prof, patch);
    try{ localStorage.setItem('nadir.profile.v1', JSON.stringify(prof)); }catch(e){}
  }
  async bootCity(c){
    try{ this.setState({status:"Recherche de « "+c+" »…"});
      const g=await this.geocode(c); this.setState({status:"Récupération de la météo…"});
      const raw=await this.forecast(g.lat,g.lon,g.name); this._firstDraw=true;
      this.setState({raw, status:"", lat:g.lat, lon:g.lon});
      this.persist({lat:g.lat, lon:g.lon, place:g.name});
    }catch(err){ this.setState({status:"Ville introuvable. Exemple affiché."}); }
  }

  useGeo(){
    if(!navigator.geolocation){ this.setState({status:"Géolocalisation indisponible. Tapez votre ville."}); return; }
    this.setState({status:"Localisation en cours…"});
    navigator.geolocation.getCurrentPosition(async pos=>{
      try{ this.setState({status:"Récupération de la météo…"});
        const raw=await this.forecast(pos.coords.latitude, pos.coords.longitude, "Votre position");
        this._firstDraw=true;
        this.setState({raw, status:"", lat:pos.coords.latitude, lon:pos.coords.longitude});
        this.persist({lat:pos.coords.latitude, lon:pos.coords.longitude, place:"Votre position"});
      }catch(e){ this.setState({status:"Météo indisponible"+(e&&e.message?" ("+e.message+")":"")}); }
    }, err=>{
      this.setState({status: err.code===1 ? "Localisation refusée. Tapez votre ville." : err.code===2 ? "Position introuvable. Tapez votre ville." : "Trop long. Tapez votre ville."});
    }, {timeout:9000, maximumAge:600000});
  }
  async submitCity(e){
    e.preventDefault();
    const c=((this.cityRef.current && this.cityRef.current.value)||"").trim(); if(!c) return;
    try{ this.setState({status:"Recherche de « "+c+" »…"});
      const g=await this.geocode(c); this.setState({status:"Récupération de la météo…"});
      const raw=await this.forecast(g.lat, g.lon, g.name); this._firstDraw=true;
      this.setState({raw, status:"", lat:g.lat, lon:g.lon});
      this.persist({lat:g.lat, lon:g.lon, place:g.name});
    }catch(err){ this.setState({status: err.message==="introuvable" ? "Ville introuvable. Vérifiez l'orthographe." : "Connexion impossible. Réessayez dans un instant."}); }
  }

  async obProcessCity(){
    const c=((this.obCityRef.current && this.obCityRef.current.value)||"").trim();
    if(!c){ this.setState(s=>({obStep:s.obStep+1, obStatus:''})); return; }
    try{ this.setState({obStatus:"Recherche de « "+c+" »…"});
      const g=await this.geocode(c); this.setState({obStatus:"Récupération de la météo…"});
      const raw=await this.forecast(g.lat, g.lon, g.name); this._firstDraw=true;
      this.setState(s=>({raw, lat:g.lat, lon:g.lon, obStatus:'', obStep:s.obStep+1}));
      this.persist({lat:g.lat, lon:g.lon, place:g.name});
    }catch(err){ this.setState({obStatus: err.message==="introuvable" ? "Ville introuvable. Vérifiez l'orthographe, ou continuez sans ville." : "Connexion impossible. Réessayez, ou continuez sans ville."}); }
  }
  obUseGeo(){ /* comme useGeo mais statuts dans obStatus et avance obStep en cas de succès */ }
  obBack(){ this.setState(s=>({obStep:Math.max(0,s.obStep-1), obStatus:''})); }
  obNextStep(){ this.setState(s=>({obStep:s.obStep+1, obStatus:''})); }
  obFinish(){ this.setState({onboarding:false}); this.persist({onboarded:true}); }
  obSkip(){ this.setState({onboarding:false}); this.persist({onboarded:true}); }
  toggleExpo(o){
    this.setState(s=>{
      const sel=[s.expo]; if(s.expo2&&s.expo2!==s.expo) sel.push(s.expo2);
      const i=sel.indexOf(o);
      if(i>=0){ if(sel.length>1) sel.splice(i,1); }        // décocher (jamais zéro)
      else { sel.push(o); if(sel.length>2) sel.shift(); }  // ajouter, max 2 (évince le plus ancien)
      return { expo:sel[0], expo2:sel[1]||null };
    }, ()=>this.persist({expo:this.state.expo, expo2:this.state.expo2}));
  }

  // Début / fin du premier créneau, en vrais Date (heure locale de la ville).
  windowTimes(comp){
    comp = comp || this.compute();
    if(!comp || !comp.runs.length) return null;
    const d=comp.d, first=comp.runs[0];
    return { startD:new Date(d.times[first[0]].getTime()), endD:new Date(d.times[first[1]].getTime()+3600e3) };
  }
  hhmm(d){ return this.pad2(d.getHours())+":"+this.pad2(d.getMinutes()); }
  delta(ms){ const m=Math.max(0,Math.round(ms/60000)); if(m<60) return m+" min"; const h=Math.floor(m/60), mm=m%60; return mm? h+" h "+this.pad2(mm) : h+" h"; }

  // Arme / désarme l'alarme. Ici on ne fait que mémoriser le choix ; c'est iOS
  // (UNUserNotificationCenter) qui déclenchera la vraie alarme système dans l'app native.
  toggleAlarm(which){
    const key = which==='start' ? 'alarmStart' : 'alarmEnd';
    this.setState(s=>({ [key]: !s[key] }), ()=>this.persist({ alarmStart:this.state.alarmStart, alarmEnd:this.state.alarmEnd }));
  }

  renderVals(){
    // ... (mapping affichage)
    const massHintMap={leg:"Exemple : cloison, bois, préfabriqué", moy:"Exemple : brique creuse, parpaing", lou:"Exemple : pierre, béton, brique pleine"};
    const airHintMap={fai:"Exemple : une fenêtre entrouverte", moy:"Exemple : une fenêtre grande ouverte", for:"Exemple : plusieurs fenêtres grand ouvertes, ou un ventilateur"};
    const expoHintMap={nord:"Peu de soleil direct.", est:"Soleil direct le matin.", sud:"Soleil direct en milieu de journée.", ouest:"Soleil direct l'après-midi et en soirée."};
    // dual : OPP opposées => "Traversant {A + B} — façades opposées, fort courant d'air possible."
    //        sinon        => "Traversant {A + B} — logement d'angle, courant d'air possible."
    // verdictColor : hasWindow ? "#fff" : "#ff3b1d" ; locDotColor : demo ? "#8c8c8c" : "#5ad17a"
    // tiLabel : (Ti%1 ? fmt1(Ti) : Ti.toFixed(0)) + " °C" ; slider 20..34 step 0.5
    // alarmes : alarmAvail = fin du créneau pas passée ; start désactivée si début passé ("Créneau déjà ouvert"),
    //   sinon meta "Dans "+delta ; heure hhmm ; switch vert #5ad17a, off #39393d, disabled #141414 opacity .5 ;
    //   alarmStartChecked = alarmStart && !startPast.
    // note alarmes : "Alarme système : sonne même app fermée, puis se répète à +3 et +6 min avant de s'arrêter."
  }
}
