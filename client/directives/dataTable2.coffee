angular.module('gint.ui').directive 'giDt2property'
,['$compile', '$timeout'
, ($compile, $timeout) ->
  restrict: 'A'
  compile: (element, attrs) ->
    body = '{{item.' + attrs.giDt2property + '}}'
    element.append(body)
    () ->
      return
]

angular.module('gint.ui').directive 'giDt2button'
, ['$compile'
, ($compile) ->
  restrict: 'A'
  compile: (element, attrs) ->
    body = '<button class="btn btn-info" ng-click="click()">' + attrs.text + '</button>'
    element.append(body)

    #compile returns a linking function
    (scope, elem, attrs) ->
      scope.click = () ->
        scope.$emit attrs.event, scope.item[attrs.arg]
]

angular.module('gint.ui').controller 'gintuidt2itemcontroller'
, [ '$scope', '$element'
, ($scope, $element) ->
    $scope.$watch () ->
      $scope.columns
    , (newValue, oldValue) ->
      if newValue isnt oldValue
        $slement.children().remove()
        render($element, $scope)
        $compile($element.contents())($scope)
    , true
]

angular.module('gint.ui').directive 'gintuidt2item'
, [ '$compile'
, ($compile) ->

  createAttrList = (attrsObj) ->
    res = ""
    for key, value of attrsObj
      if value?
        res += key + '="' + value + '" '
      else
        res += key + ' '
    res

  createTdProperty = (attrsObj) ->
    angular.element('<table><tr><td ' + createAttrList(attrsObj) + ' ></td></tr></table>')
    .find 'td'

  render = (element, scope) ->
    for column in scope.columns
      if column.visible
        html = null
        attrsObj = {}
        if column.type is 'gi-dt2property'
          attrsObj[column.type] = column.property
        else if column.type is 'gi-dt2button'
          attrsObj[column.type] = null
          attrsObj.text = column.text
          attrsObj.event = column.eventName
          attrsObj.arg = column.property
        
        html = $compile(createTdProperty(attrsObj))(scope)
        element.append(html)

  restrict: 'A'
  scope:
    item: '='
    columns: '='
  controller: 'gintuidt2itemcontroller'
  compile: () ->
    (scope, element) ->
      render(element, scope)
]

angular.module('gint.ui').directive 'giDatatable2'
, [ '$filter', '$timeout', '$compile'
, ($filter, $timeout, $compile) ->
  restrict: 'E'
  templateUrl: '/views/dataTable2.html'
  scope:
    items: '='
    options: '='
  link: ($scope, elem, attrs) ->
    aPromise = null
    $scope.filteredItems = []
    $scope.groupedItems = []
    $scope.itemsPerPage = 20
    $scope.pagedItems = []
    $scope.currentPage = 0
    $scope.selectAll = "All"

    $scope.$watch 'items.length', () ->
      refresh()
    
    #refresh on new query, after a delay
    $scope.$watch 'query', () ->
      if aPromise
        $timeout.cancel aPromise

      aPromise = $timeout refresh, 500
      aPromise

    $scope.$watch 'currentPage', () ->
      calculateCountMessage()

    calculateCountMessage = () ->
      if $scope.currentPage? and $scope.items? and $scope.pagedItems?
        start = $scope.currentPage * $scope.itemsPerPage + 1
        end = $scope.currentPage * $scope.itemsPerPage
        if $scope.pagedItems[$scope.currentPage]?.length?
          end = start + $scope.pagedItems[$scope.currentPage]?.length - 1
        else
          start = 0
          end = 0
    
        total = $scope.filteredItems.length
        $scope.countMessage = "Showing " + start + " to " +  end + " of " + total
      else
        $scope.countMessage = ""

    groupToPages = () ->
      if $scope.filteredItems?
        $scope.pagedItems = []
        for thing, i in $scope.filteredItems
          if (i % $scope.itemsPerPage == 0)
            $scope.pagedItems[Math.floor(i / $scope.itemsPerPage)] =
              [ $scope.filteredItems[i] ]
          else
            $scope.pagedItems[Math.floor(i / $scope.itemsPerPage)]
            .push($scope.filteredItems[i])

    refresh = () ->     
      #allow the parent controller the opportunity to pre-filter
      if $scope.options.customSearch
        $scope.filteredItems = $scope.search {query: $scope.query}
      else
        $scope.filteredItems = $filter('filter')($scope.items , (item) ->
          #we're not searching for anything - so return true
          if not $scope.query
            return true
          
          found = false
          angular.forEach $scope.options.columns, (column) ->
            if not found
              if column.search
                if column.type is 'gi-dt2property'

                  found = true unless $filter('lowercase')(
                    item[column.property].toString()
                  )
                  .indexOf($filter('lowercase')($scope.query)) is -1
                else if column.type is 'gi-dt2filter'
                  found = true unless $filter('lowercase')(
                    $filter(column.property)(item)
                  )
                  .indexOf($filter('lowercase')($scope.query)) is -1
          found
        )
      #sort the items before they go for pagination
      if $scope.options.sortProperty
        if $scope.options.sortDirection is "asc"
          sortDir = false
        else
          sortDir = true

        $scope.filteredItems = $filter('orderBy')($scope.filteredItems
        , (item) ->
          item[$scope.options.sortProperty]
        , sortDir )

      if $scope.options.customSort
        $scope.filteredItems = $scope.sort {items: $scope.filteredItems}

      $scope.currentPage = 0
      # now group by pages
      groupToPages()
      calculateCountMessage()
      $scope.options.refreshRequired = false
      return

    selectionChanged = (item) ->
      $scope.$emit 'selectionChanged', item
      unless $scope.options.multi
        angular.forEach $scope.items, (other) ->
          if item._id isnt other._id
            other.selected = false
      $scope.selectedItems = $filter('filter')($scope.items, (item) ->
        item.selected)        

    $scope.toggleSelectAll = ->
      if $scope.selectAll is "All"
        angular.forEach $scope.items, (item) ->
          item.selected = true
        $scope.selectedItems = $scope.items
        $scope.selectAll = "None"
      else
        angular.forEach $scope.items, (item) ->
          item.selected = false
        $scope.selectedItems = []
        $scope.selectAll = "All"

    $scope.selectRow = (item) ->
      item.selected = not item.selected
      selectionChanged item

    $scope.selectAllClick = (e, item) ->
      e.stopPropagation()
      selectionChanged item


    $scope.range = (currentPage) ->
      max = $scope.pagedItems.length - 1
      if max < 1
        return []

      end =  if max > currentPage + 1 then currentPage + 2
      start = currentPage - 2

      if currentPage < 3
        start = 0
        end = 4 if max > 3

      if currentPage > max - 3
        end = max
        start = (max - 4) if max > 3

      result = []
      for num in [start..end]
        result.push num
      result

    $scope.prevPage = ->
      if $scope.currentPage > 0
        $scope.currentPage = $scope.currentPage - 1

    $scope.nextPage = ->
      if $scope.currentPage < $scope.pagedItems.length - 1
        $scope.currentPage = $scope.currentPage + 1

    $scope.setPage = (n) ->
      $scope.currentPage = n

]