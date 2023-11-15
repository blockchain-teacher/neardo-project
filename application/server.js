// 모듈포함
var express = require('express');
const {Gateway, Wallets } = require('fabric-network');
const FabricCAServices = require('fabric-ca-client');

var path = require('path');
var fs = require('fs');

// 지갑라이브러리 포함
const { buildCAClient, enrollAdmin, registerAndEnrollUser } = require('./lib/cautil.js');
const { buildCCPOrg2, buildWallet } = require('./lib/apputil.js');

// ccp 객체화
const ccp = buildCCPOrg2();

// 서버설정
const mspOrg2 = 'Org2MSP';
const walletPath = path.join(__dirname, 'wallet');
const channelName = 'eggchannel';
const chaincodeName = 'egg';

var app = express();
app.use('/public', express.static( path.join(__dirname, 'public')));
app.use(express.json());
app.use(express.urlencoded({extended: true}));

// HTML 라우팅
app.get('/', (req, res) => {
    res.sendFile(__dirname+("/views/index_theme.html"));
})
app.get('/wallet', (req, res) => {
    res.sendFile(__dirname+("/views/wallet.html"));
})
app.get('/eggcreate', (req, res) => {
    res.sendFile(__dirname+("/views/create.html"));
})
app.get('/eggquery', (req, res) => {
    res.sendFile(__dirname+("/views/query.html"));
})

// (TODO) 배송요청 html GET
app.get('/eggrequestship', (req, res) => {
    res.sendFile(__dirname+"/views/requestship.html");
})
// (TODO) 배송 html GET
app.get('/eggship', (req, res) => {
    res.sendFile(__dirname+"/views/ship.html");
})

// REST 라우팅
app.post('/admin', async(req, res)=>{
    const adminid = req.body.id;
    const adminpw = req.body.password;

    console.log('/admin POST - ', adminid, adminpw);

    try {
        const wallet = await buildWallet(Wallets, walletPath);
        const caClient = buildCAClient(FabricCAServices, ccp, 'ca.org2.example.com');
        await enrollAdmin(caClient, wallet, mspOrg2, adminid, adminpw);

        var result = {}
        result.result = 'success';
        result.msg = 'admin certificate is enrolled';
        res.json(result);

    } catch (error) {
        console.log(`/admin POST ERROR :  ${error}`);
        var result = {}
        result.result = 'failed';
        result.error = 'admin certificate is not enrolled';
        res.json(result);
    }
})

app.post('/user', async(req, res)=>{
    const id = req.body.id;
    const role = req.body.role;
    const department = req.body.department;

    console.log('/user POST - ', id, role, department);

    try {
        const wallet = await buildWallet(Wallets, walletPath);
        const caClient = buildCAClient(FabricCAServices, ccp, 'ca.org2.example.com');
        //await enrollAdmin(caClient, wallet, mspOrg2, adminid, adminpw);
        await registerAndEnrollUser(caClient, wallet, mspOrg2, "admin", id, role, department);

        var result = `{"result":"success","msg":"user certificate is enrolled"}`
        res.json(JSON.parse(result));

    } catch (error) {
        console.log(`/user POST ERROR :  ${error}`);

        var result = {}
        result.result = 'failed';
        result.error = 'user certificate is not enrolled';
        res.json(result);
    }
})

// Impl. 2
app.get('/egg', async(req,res)=>{
    const cert = req.query.cert;
    const eid = req.query.eid;

    console.log("/egg GET : ", cert, eid)

    const wallet = await buildWallet(Wallets, walletPath);
    const gateway = new Gateway();
   
    try {
        
        await gateway.connect(ccp, {
            wallet,
            identity: cert,
            discovery: {enabled: true, asLocalhost: true }
        });

        const network = await gateway.getNetwork(channelName);
        const contract = network.getContract(chaincodeName);
        var cc_result = await contract.evaluateTransaction("QueryEgg", eid);

        var doc_json = {}
        doc_json.result = "success"
        // doc_json.msg=cc_result
        doc_json.msg=JSON.parse(cc_result);
        res.send(doc_json);

    } catch (error) {
        console.log(error)
        var doc_json = {}
        doc_json.result = "failed"
        doc_json.error = error.message
        res.send(doc_json);
    } finally {
        // Gateway 연결종료
        gateway.disconnect();
    }

});

// Impl. 1
app.post('/egg', async(req,res)=>{
    const cert = req.body.cert;
    const cid = req.body.cid;
    const eid = req.body.eid;
    const sdate = req.body.sdate;
    const count = req.body.count;
    const owner = req.body.owner;

    console.log("/egg POST : ", cert, cid, eid, sdate, count, owner)

    const wallet = await buildWallet(Wallets, walletPath);
    const gateway = new Gateway();

    try {
        // tx 연동 GW -> CHANNEL -> CC -> SubmitTx
        await gateway.connect(ccp, {
            wallet,
            identity: cert, 
            discovery: { enabled: true, asLocalhost: true }
        });

        const network = await gateway.getNetwork(channelName);

        const contract = await network.getContract(chaincodeName);

        await contract.submitTransaction('RegisterEgg', cid, eid, sdate, count, owner);

        var doc_json = {}
        doc_json.result = "success"
        doc_json.msg = "tx is submitted."
        res.send(doc_json);

    } catch (error) {
        console.log(error.message)
        var doc_json  = {}
        doc_json.result = "failed"
        doc_json.error = error.message
        res.send(doc_json);

    } finally {
        gateway.disconnect();
    }

});

app.post('/egg/shipment', async(req,res)=>{
    const cert = req.body.cert;
    const eid = req.body.eid;
    const shipinfo = req.body.shipinfo;

    console.log("/egg/shipmemt POST : ", cert, eid, shipinfo);

    const wallet = await buildWallet(Wallets, walletPath);
    const gateway = new Gateway();

    try {
        await gateway.connect(ccp, {
            wallet,
            identity: cert,
            discovery: { enable: true, asLocalhost: true }
        });
        const network = await gateway.getNetwork(channelName);
        const contract = await network.getContract(chaincodeName);
        await contract.submitTransaction('RequestShip', eid, shipinfo);

        var doc_json = {};
        doc_json.result = 'success';
        doc_json.msg = "tx is submitted";
        res.send(doc_json);

    } catch (error) {
        console.log(error.message);
        var doc_json = {};
        doc_json.result = 'failed';
        doc_json.error = error.message;
        res.send(doc_json);
        
    } finally {
        gateway.disconnect();
    }

});

app.put('/egg/shipment/:eid', async(req,res)=>{
    const cert = req.body.cert;
    const eid = req.params.eid;

    console.log("/egg/shipmemt PUT : ", cert, eid);

    const wallet = await buildWallet(Wallets, walletPath);
    const gateway = new Gateway();

    try {
        await gateway.connect(ccp, {
            wallet,
            identity: cert,
            discovery: { enable: true, asLocalhost: true }
        });
        const network = await gateway.getNetwork(channelName);
        const contract = await network.getContract(chaincodeName);
        await contract.submitTransaction('ShipEgg', eid);

        var doc_json = {};
        doc_json.result = 'success';
        doc_json.msg = "tx is submitted";
        res.json(doc_json);

    } catch (error) {
        console.log(error.message);
        var doc_json = {};
        doc_json.result = 'failed';
        doc_json.error = error.message;
        res.json(doc_json);
        
    } finally {
        gateway.disconnect();
    }
});

// Impl. 3
app.get('/egg/history', async(req,res)=>{
    const cert = req.query.cert;
    const id = req.query.eid;

    console.log("/egg/history GET : ", cert, id);

    const wallet = await buildWallet(Wallets, walletPath);
    const gateway = new Gateway();

    try {
        
        await gateway.connect(ccp, {
            wallet,
            identity: cert,
            discovery: {enabled: true, asLocalhost: true }
        });

        const network = await gateway.getNetwork(channelName);
        const contract = network.getContract(chaincodeName);
        var cc_result = await contract.evaluateTransaction("QueryEggHistory", id);

        var doc_json = {}
        doc_json.result = "success"
        // doc_json.msg=cc_result
        doc_json.msg=JSON.parse(cc_result);
        res.send(doc_json);

    } catch (error) {
        console.log(error)
        var doc_json = {}
        doc_json.result = "failed"
        doc_json.error = error.message
        res.send(doc_json);
    } finally {
        // Gateway 연결종료
        gateway.disconnect();
    }
});

// 서버시작
app.listen(3000, () => {
    console.log("Server is started. : 3000");
})