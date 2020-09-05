// to run the script do:
// mongo < bin/setup_db.js

// db.forward_marks.remove({})
//db.forward_marks.findOne();


//use isoexpress;
//db.wholesale_load_cost.dropIndexes()
//db.wholesale_load_cost.createIndexe({'ptid': 1, 'date': 1}, {'unique': true});

//use marks
//db.curve_ids.dropIndexes()
//db.curve_ids.createIndex({'curveId': 1}, {'unique': true})
//db.curve_ids.createIndex({'commodity': 1})
//db.curve_ids.createIndex({
//    'commodity': 1,
//    'region': 1,
//    'serviceType': 1})



//use marks
//db.forward_marks.dropIndexes()
//db.forward_marks.createIndex({'fromDate': 1})
//db.forward_marks.createIndex({
//    'curveId': 1,
//    'markType': 1,
//    'fromDate': 1
//    }, {'unique': true})



//use mis
//db.sd_arrawdsum.createIndex({
//        'account': 1,
//        'tab': 1,
//        'month': 1,
//        'version': 1})
//db.sd_arrawdsum.createIndex({
//        'account': 1,
//        'tab': 1,
//        'month': 1,
//        'version': 1,
//        'Subaccount ID': 1}, {
//        partialFilterExpression: {
//            'Subaccount ID': {'$exists': true}
//        }
//     })

