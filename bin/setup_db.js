// to run the script do:
// mongo < bin/setup_db.js

use marks
show collections
//db.forward_marks.findOne();

use mis
db.sd_arrawdsum.createIndex({
        'account': 1,
        'tab': 1,
        'month': 1,
        'version': 1})
db.sd_arrawdsum.createIndex({
        'account': 1,
        'tab': 1,
        'month': 1,
        'version': 1,
        'Subaccount ID': 1}, {
        partialFilterExpression: {
            'Subaccount ID': {'$exists': true}
        }
     })